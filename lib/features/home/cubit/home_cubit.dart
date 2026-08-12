import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:football_live_score/models/fixture_model.dart';
import 'home_state.dart';

// ═══════════════════════════════════════════════════════════════
// HOME CUBIT (ViewModel)
//
// MVVM role: ViewModel
//   - Owns all business logic for the Home tab
//   - Calls API (in a real app, this would delegate to a Repository)
//   - Emits HomeState (the Model)
//   - Zero Flutter widget imports — pure logic
//
// Pagination: DRF limit/offset
//   API returns: { "count": 169, "next": "...?offset=10", "results": [...] }
//   loadMoreFixtures() is called by HomeScreen scroll listener
//   when user reaches bottom of list.
//
// State management: flutter_bloc / Cubit
// ═══════════════════════════════════════════════════════════════

// ─── API Base (move to config/constants.dart in future) ───────
const String apiBase = 'http://69.164.247.167/api/live/v1';

// Default page size — matches server default
const int _pageLimit = 10;

class HomeCubit extends Cubit<HomeState> {
  int _requestVersion = 0;

  static const int _maxAutoRetry = 5;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _httpTimeout = Duration(seconds: 15);
  static const int _upcomingDays = 7;

  // HomeCubit() : super(const HomeState()) {
  //   fetchFixtures();
  // }

  HomeCubit() : super(const HomeState()) {
    final today = _formatDate(DateTime.now());
    emit(state.copyWith(selectedDate: today, liveOnly: false));
    fetchFixturesByDate(today);
}

  // ─── Public API (called by View) ──────────────────────────────

  void toggleLiveOnly() => emit(state.copyWith(liveOnly: !state.liveOnly));

  void selectDate(String? date) {
    if (date == null) {
      emit(state.copyWith(
        liveOnly: true,
        clearSelectedDate: true,
        clearNextUrl: true,
        isLoading: true,
        hasMore: false,
        retryAttempt: 0,
      ));
      fetchFixtures();
    } else {
      emit(state.copyWith(
        selectedDate: date,
        liveOnly: false,
        clearNextUrl: true,
        isLoading: true,
        hasMore: false,
        retryAttempt: 0,
      ));
      fetchFixturesByDate(date);
    }
  }

  void retry() {
    if (state.selectedDate != null) {
      fetchFixturesByDate(state.selectedDate!);
    } else {
      fetchFixtures();
    }
  }

  // ─── Pagination: Load next page ───────────────────────────────
  // Called by HomeScreen when user scrolls to bottom.
  // Only works in date-filter mode (selectedDate != null).
  // In live/all mode we already fetched everything upfront.

  Future<void> loadMoreFixtures() async {
    // Guard: already loading, no more pages, or no next URL
    if (state.isLoadingMore || !state.hasMore || state.nextUrl == null) return;

    debugPrint('[HomeCubit] 📄 Loading more: ${state.nextUrl}');
    emit(state.copyWith(isLoadingMore: true));

    try {
      final response = await http
          .get(Uri.parse(state.nextUrl!))
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final paged = _parsePagedResponse(response.body, 'load-more');
        final seenIds = state.fixtures.map((f) => f.fixtureId).toSet();
        final newFixtures = paged.fixtures
            .where((f) => seenIds.add(f.fixtureId))
            .toList();

        final merged = _sortByPriority([...state.fixtures, ...newFixtures]);

        debugPrint('[HomeCubit] ✅ Loaded ${newFixtures.length} more fixtures. '
            'Total: ${merged.length}. hasMore: ${paged.nextUrl != null}');

        emit(state.copyWith(
          fixtures: merged,
          isLoadingMore: false,
          hasMore: paged.nextUrl != null,
          nextUrl: paged.nextUrl,
        ));
      } else {
        debugPrint('[HomeCubit] ⚠️ loadMore HTTP ${response.statusCode}');
        emit(state.copyWith(isLoadingMore: false, hasMore: false));
      }
    } on TimeoutException {
      debugPrint('[HomeCubit] ⚠️ loadMore timeout');
      emit(state.copyWith(isLoadingMore: false));
    } catch (e) {
      debugPrint('[HomeCubit] ⚠️ loadMore error: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  // ─── League Priority ──────────────────────────────────────────

  int _getLeaguePriority(String name) {
    final s = name.toLowerCase();
    if (s.contains('world cup')) return 1;
    if (s.contains('champions league')) return 2;
    if (s.contains('euro')) return 3;
    if (s.contains('premier league')) return 4;
    if (s.contains('la liga')) return 5;
    if (s.contains('serie a')) return 6;
    if (s.contains('bundesliga')) return 7;
    if (s.contains('ligue 1')) return 8;
    return 99;
  }

  // ─── Sort: Live → Upcoming → Finished ────────────────────────

  List<FixtureModel> _sortByPriority(List<FixtureModel> fixtures) {
    final sorted = List<FixtureModel>.from(fixtures);
    sorted.sort((a, b) {
      int statusOrder(FixtureModel f) {
        if (f.isLive) return 0;
        if (f.isNS && !f.isProbablyFinished) return 1;
        return 2;
      }

      final soA = statusOrder(a);
      final soB = statusOrder(b);
      if (soA != soB) return soA.compareTo(soB);

      final pa = _getLeaguePriority(a.league['name']?.toString() ?? '');
      final pb = _getLeaguePriority(b.league['name']?.toString() ?? '');
      if (pa != pb) return pa.compareTo(pb);

      final nameCompare = (a.league['name']?.toString() ?? '')
          .compareTo(b.league['name']?.toString() ?? '');
      if (nameCompare != 0) return nameCompare;

      return (a.timestamp ?? 0).compareTo(b.timestamp ?? 0);
    });
    return sorted;
  }

  // ─── Date Formatting ──────────────────────────────────────────

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // ─── JSON Helpers ─────────────────────────────────────────────

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['data'] is List) return data['data'] as List;
      if (data['response'] is List) return data['response'] as List;
      if (data['results'] is List) return data['results'] as List;
    }
    return [];
  }

  // ─── NEW: Parse DRF paged response ───────────────────────────
  // Extracts: count, next URL, results list
  // Works with: { "count": 169, "next": "...", "results": [...] }

  _PagedResult _parsePagedResponse(String body, String context) {
    if (body.isEmpty) {
      debugPrint('⚠️ [$context] Empty response body');
      return const _PagedResult(fixtures: [], nextUrl: null, count: 0);
    }

    try {
      final data = json.decode(body);
      if (data is Map) {
        final nextUrl = data['next'] as String?;
        final count = (data['count'] as num?)?.toInt() ?? 0;
        final list = _extractList(data);
        final fixtures = _safeParseFixtures(list);
        debugPrint('✅ [$context] count=$count next=${nextUrl != null ? "yes" : "null"} '
            'parsed=${fixtures.length}');
        return _PagedResult(fixtures: fixtures, nextUrl: nextUrl, count: count);
      }
      // Fallback: bare list (no pagination envelope)
      final list = _extractList(data);
      return _PagedResult(
          fixtures: _safeParseFixtures(list), nextUrl: null, count: list.length);
    } catch (e) {
      debugPrint('⚠️ [$context] JSON decode failed: $e');
    }

    // Last resort: extract individual objects
    final candidates = _extractIndividualJsonObjects(body);
    return _PagedResult(
        fixtures: _safeParseFixtures(candidates), nextUrl: null, count: candidates.length);
  }

  List<FixtureModel> _safeParseFixtures(List<dynamic> rawList) {
    final fixtures = <FixtureModel>[];
    for (int i = 0; i < rawList.length; i++) {
      try {
        if (rawList[i] is Map<String, dynamic>) {
          fixtures.add(FixtureModel.fromJson(rawList[i] as Map<String, dynamic>));
        } else if (rawList[i] is Map) {
          fixtures.add(FixtureModel.fromJson(Map<String, dynamic>.from(rawList[i] as Map)));
        }
      } catch (e) {
        debugPrint('⚠️ [HomeCubit] Skipping malformed fixture at index $i: $e');
      }
    }
    return fixtures;
  }

  _ParseResult _resilientParseFixtures(String body, String context) {
    if (body.isEmpty) {
      debugPrint('⚠️ [$context] Empty response body');
      return const _ParseResult(fixtures: []);
    }

    try {
      final data = json.decode(body);
      final list = _extractList(data);
      debugPrint('✅ [$context] JSON decoded, ${list.length} raw items');
      final fixtures = _safeParseFixtures(list);
      return _ParseResult(fixtures: fixtures, totalCandidates: list.length);
    } catch (e) {
      debugPrint('⚠️ [$context] Full JSON decode failed, attempting partial extraction...');
    }

    final candidates = _extractIndividualJsonObjects(body);
    if (candidates.isEmpty) {
      return const _ParseResult(fixtures: [], hadParseFailure: true, totalCandidates: 0);
    }

    final fixtures = <FixtureModel>[];
    int failCount = 0;

    for (final c in candidates) {
      try {
        fixtures.add(FixtureModel.fromJson(c));
      } catch (_) {
        failCount++;
      }
    }

    return _ParseResult(
      fixtures: fixtures,
      hadParseFailure: failCount > 0,
      failedCount: failCount,
      totalCandidates: candidates.length,
    );
  }

  List<Map<String, dynamic>> _extractIndividualJsonObjects(String body) {
    int arrayStart = -1;
    const patterns = ['"data":[', '"response":[', '"results":['];
    for (final pattern in patterns) {
      final idx = body.indexOf(pattern);
      if (idx >= 0) {
        arrayStart = idx + pattern.length - 1;
        break;
      }
    }
    if (arrayStart < 0) arrayStart = body.indexOf('[');
    if (arrayStart < 0 || arrayStart >= body.length || body[arrayStart] != '[') return [];

    final objectSubstrings = <String>[];
    int i = arrayStart + 1;

    while (i < body.length) {
      while (i < body.length && ' \n\r\t,'.contains(body[i])) i++;
      if (i >= body.length || body[i] == ']') break;
      if (body[i] != '{') {
        i++;
        continue;
      }

      int depth = 0;
      int start = i;
      bool inStr = false;
      int strLen = 0;
      int objCharCount = 0;

      while (i < body.length) {
        final c = body[i];
        objCharCount++;

        if (inStr) {
          strLen++;
          if (c == '\\' && i + 1 < body.length) {
            i += 2;
            objCharCount++;
            continue;
          }
          if (c == '"') {
            inStr = false;
            strLen = 0;
          }
        } else {
          if (c == '"') {
            inStr = true;
            strLen = 0;
          } else if (c == '{') {
            depth++;
          } else if (c == '}') {
            depth--;
            if (depth == 0) {
              objectSubstrings.add(body.substring(start, i + 1));
              i++;
              break;
            }
          }
        }

        if (inStr && strLen > 2000) {
          inStr = false;
          strLen = 0;
        }
        if (depth > 0 && objCharCount > 80000) {
          final recovery = body.indexOf('},{', i);
          if (recovery >= 0) {
            i = recovery + 2;
            depth = 0;
            break;
          }
          break;
        }
        i++;
      }
    }

    final results = <Map<String, dynamic>>[];
    for (final s in objectSubstrings) {
      try {
        final parsed = json.decode(s);
        if (parsed is Map) results.add(Map<String, dynamic>.from(parsed));
      } catch (_) {}
    }
    return results;
  }

  // ─── Network: Fetch with retry + UI progress ──────────────────

  Future<http.Response?> _fetchWithAutoRetry(String url, int currentVersion) async {
    http.Response? response;
    for (int attempt = 1; attempt <= _maxAutoRetry; attempt++) {
      if (_requestVersion != currentVersion) return null;

      emit(state.copyWith(retryAttempt: attempt));

      try {
        response = await http.get(Uri.parse(url)).timeout(_httpTimeout);
        if (response.statusCode >= 500 && attempt < _maxAutoRetry) {
          response = null;
          await Future.delayed(_retryDelay);
          continue;
        }
        break;
      } on TimeoutException {
        if (attempt < _maxAutoRetry) await Future.delayed(_retryDelay);
      } catch (_) {
        if (attempt < _maxAutoRetry) await Future.delayed(_retryDelay);
      }
    }

    if (_requestVersion == currentVersion) emit(state.copyWith(retryAttempt: 0));
    return response;
  }

  // ─── Network: Single-date fetch — fetches ALL pages ──────────
  // Changed: now loops through all "next" pages before returning,
  // so the initial load for a date is always complete.
  // Pagination after this is handled by loadMoreFixtures().

  Future<_DateFetchResult> _fetchDateFixtures(String date, int version) async {
    final allFixtures = <FixtureModel>[];
    String? currentUrl = '$apiBase/fixtures/?date=$date&limit=$_pageLimit';
    String? finalNextUrl;

    try {
      // Fetch first page only on initial load.
      // User will trigger more pages by scrolling.
      final response = await http
          .get(Uri.parse(currentUrl))
          .timeout(_httpTimeout);

      if (_requestVersion != version) {
        return const _DateFetchResult(fixtures: [], success: false, nextUrl: null);
      }

      if (response.statusCode == 200) {
        final paged = _parsePagedResponse(response.body, 'fixtures-$date-p1');
        allFixtures.addAll(paged.fixtures);
        finalNextUrl = paged.nextUrl;
        debugPrint('✅ [HomeCubit] Date $date page 1: ${paged.fixtures.length} fixtures, '
            'total count: ${paged.count}, hasMore: ${finalNextUrl != null}');
        return _DateFetchResult(
            fixtures: allFixtures, success: true, nextUrl: finalNextUrl);
      }

      debugPrint('⚠️ [HomeCubit] Date $date: HTTP ${response.statusCode}');
      return const _DateFetchResult(fixtures: [], success: false, nextUrl: null);
    } on TimeoutException {
      debugPrint('⚠️ [HomeCubit] Date $date: Timeout');
      return const _DateFetchResult(fixtures: [], success: false, nextUrl: null);
    } catch (e) {
      debugPrint('⚠️ [HomeCubit] Date $date fetch error: $e');
      return const _DateFetchResult(fixtures: [], success: false, nextUrl: null);
    }
  }

  // ─── Main Fetch: LIVE + TODAY + NEXT 7 DAYS ──────────────────

  Future<void> fetchFixtures() async {
    final currentVersion = ++_requestVersion;
    emit(state.copyWith(
        isLoading: true, error: null, retryAttempt: 0, hasMore: false, clearNextUrl: true));

    final allFixtures = <FixtureModel>[];
    final seenIds = <String>{};
    bool anySuccess = false;

    // Step 1: Live fixtures (with retry UI)
    debugPrint('📡 [HomeCubit] Step 1: Fetching live fixtures...');
    final liveResponse = await _fetchWithAutoRetry('$apiBase/live-fixtures/', currentVersion);
    if (_requestVersion != currentVersion) return;

    if (liveResponse != null && liveResponse.statusCode == 200) {
      final result = _resilientParseFixtures(liveResponse.body, 'live-fixtures');
      for (final f in result.fixtures) {
        if (seenIds.add(f.fixtureId)) allFixtures.add(f);
      }
      anySuccess = true;
      debugPrint('✅ [HomeCubit] Live fixtures: ${result.fixtures.length} loaded');
    }

    // Step 2: Today + next 7 days in parallel (first page each)
    if (_requestVersion != currentVersion) return;
    final today = DateTime.now();
    final dateFutures = List.generate(_upcomingDays + 1, (i) {
      final d = DateTime(today.year, today.month, today.day + i);
      return _fetchDateFixtures(_formatDate(d), currentVersion);
    });

    debugPrint('📡 [HomeCubit] Step 2: Fetching today + next $_upcomingDays days (parallel)...');
    final dateResults = await Future.wait(dateFutures);
    if (_requestVersion != currentVersion) return;

    for (final r in dateResults) {
      if (r.success) {
        for (final f in r.fixtures) {
          if (seenIds.add(f.fixtureId)) allFixtures.add(f);
        }
        anySuccess = true;
      }
    }

    if (!anySuccess) {
      emit(state.copyWith(isLoading: false, error: 'Request timed out. Please try again.'));
      return;
    }

    final sorted = _sortByPriority(allFixtures);
    debugPrint('📊 [HomeCubit] Total: ${sorted.length} '
        '(Live: ${sorted.where((f) => f.isLive).length}, '
        'Upcoming: ${sorted.where((f) => f.isNS && !f.isProbablyFinished).length}, '
        'Finished: ${sorted.where((f) => f.isProbablyFinished).length})');

    // In live/all mode: no pagination (we fetched all days upfront)
    emit(state.copyWith(
        fixtures: sorted, isLoading: false, retryAttempt: 0, hasMore: false));
  }

  // ─── Fetch by specific date (first page, pagination enabled) ──

  Future<void> fetchFixturesByDate(String date) async {
    final currentVersion = ++_requestVersion;
    emit(state.copyWith(
        isLoading: true, error: null, retryAttempt: 0, hasMore: false, clearNextUrl: true));

    final response =
        await _fetchWithAutoRetry('$apiBase/fixtures/?date=$date&limit=$_pageLimit', currentVersion);
    if (_requestVersion != currentVersion) return;

    if (response == null) {
      emit(state.copyWith(isLoading: false, error: 'Request timed out for $date.'));
      return;
    }

    if (response.statusCode == 200) {
      final paged = _parsePagedResponse(response.body, 'date-$date');
      debugPrint('[HomeCubit] fetchFixturesByDate $date: '
          '${paged.fixtures.length} fixtures, hasMore: ${paged.nextUrl != null}');

      emit(state.copyWith(
        fixtures: _sortByPriority(paged.fixtures),
        isLoading: false,
        hasMore: paged.nextUrl != null,
        nextUrl: paged.nextUrl,
      ));
    } else {
      emit(state.copyWith(isLoading: false, error: 'Server Error (${response.statusCode})'));
    }
  }
}

// ─── Internal Data Classes ────────────────────────────────────

class _ParseResult {
  final List<FixtureModel> fixtures;
  final bool hadParseFailure;
  final int failedCount;
  final int totalCandidates;

  const _ParseResult({
    required this.fixtures,
    this.hadParseFailure = false,
    this.failedCount = 0,
    this.totalCandidates = 0,
  });
}

// ─── NEW: Paged result — carries next URL from DRF response ───
class _PagedResult {
  final List<FixtureModel> fixtures;
  final String? nextUrl;
  final int count;

  const _PagedResult({
    required this.fixtures,
    required this.nextUrl,
    required this.count,
  });
}

class _DateFetchResult {
  final List<FixtureModel> fixtures;
  final bool success;
  final String? nextUrl; // ← NEW: carries "next" URL for pagination
  const _DateFetchResult({
      required this.fixtures, required this.success, required this.nextUrl});
}