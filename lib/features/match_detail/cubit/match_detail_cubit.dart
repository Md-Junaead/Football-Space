import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:football_space/features/home/cubit/home_cubit.dart'
    show apiBase;
import 'package:football_space/models/fixture_model.dart';
import 'match_detail_state.dart';

class MatchDetailCubit extends Cubit<MatchDetailState> {
  static const int _maxAutoRetry = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _httpTimeout = Duration(seconds: 15);

  bool _isClosed = false;

  MatchDetailCubit() : super(const MatchDetailState());

  @override
  void emit(MatchDetailState state) {
    if (_isClosed) return;
    super.emit(state);
  }

  @override
  Future<void> close() {
    _isClosed = true;
    return super.close();
  }

  List<dynamic> _extractList(dynamic json) {
    if (json is List) return json;
    if (json is Map) {
      if (json['data'] is List) return json['data'] as List;
      if (json['response'] is List) return json['response'] as List;
      if (json['results'] is List) return json['results'] as List;
    }
    return [];
  }

  List<dynamic> _resilientParseJsonList(String body, String context) {
    if (body.isEmpty) return [];
    try {
      final data = jsonDecode(body);
      final list = _extractList(data);
      debugPrint('📊 [_resilientParseJsonList] $context -> extracted ${list.length} items');
      // 🆕 পুরো লিস্টের প্রথম কয়েকটা আইটেম প্রিন্ট করুন (ডেটা স্ট্রাকচার বুঝতে)
      if (list.isNotEmpty) {
        debugPrint('📊 [_resilientParseJsonList] First item keys: ${(list[0] as Map).keys.join(', ')}');
      }
      return list;
    } catch (e) {
      debugPrint('⚠️ [_resilientParseJsonList] $context JSON decode failed: $e');
    }
    final extracted = _extractIndividualJsonObjects(body);
    debugPrint('📊 [_resilientParseJsonList] $context -> fallback extracted ${extracted.length} items');
    return extracted;
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

      int depth = 0, start = i;
      bool inStr = false;
      int strLen = 0, objCharCount = 0;

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
        if (depth > 0 && objCharCount > 80000) break;
        i++;
      }
    }

    final results = <Map<String, dynamic>>[];
    for (final s in objectSubstrings) {
      try {
        final parsed = jsonDecode(s);
        if (parsed is Map) results.add(Map<String, dynamic>.from(parsed));
      } catch (_) {}
    }
    return results;
  }

  Future<http.Response?> _fetchWithAutoRetry(String url) async {
    http.Response? response;
    for (int attempt = 1; attempt <= _maxAutoRetry; attempt++) {
      try {
        response = await http.get(Uri.parse(url)).timeout(_httpTimeout);
        if (response.statusCode >= 500 && attempt < _maxAutoRetry) {
          response = null;
          await Future.delayed(_retryDelay);
          continue;
        }
        break;
      } catch (_) {
        if (attempt < _maxAutoRetry) await Future.delayed(_retryDelay);
      }
    }
    return response;
  }

  String? _originalLeagueId;
  String? _originalHomeTeamId;
  String? _originalAwayTeamId;
  String? _originalSeason;

  void init(FixtureModel fixture) {
    if (_isClosed) return;

    _originalLeagueId   = fixture.leagueId;
    _originalHomeTeamId = fixture.homeTeamId;
    _originalAwayTeamId = fixture.awayTeamId;
    _originalSeason     = fixture.season;

    debugPrint('[MatchDetailCubit] init → '
        'fixtureId=${fixture.fixtureId} '
        'leagueId=$_originalLeagueId '
        'season=$_originalSeason '
        'homeTeamId=$_originalHomeTeamId '
        'awayTeamId=$_originalAwayTeamId');

    emit(MatchDetailState(fixture: fixture));
    loadFixtureDetail(fixture.fixtureId);
  }

  Future<void> loadFixtureDetail(String id) async {
    if (_isClosed) return;
    emit(state.copyWith(isLoadingTab: true, clearError: true));

    try {
      final response = await _fetchWithAutoRetry('$apiBase/fixture/$id/');
      if (_isClosed) return;

      if (response != null && response.statusCode == 200) {
        try {
          final jsonRes = jsonDecode(response.body);
          if (jsonRes is Map && !_isClosed) {
            final newFixture = FixtureModel.fromJson(
              jsonRes is Map<String, dynamic>
                  ? jsonRes
                  : Map<String, dynamic>.from(jsonRes),
            );
            final safeFixture = _restoreOriginalIds(newFixture);

            debugPrint('[MatchDetailCubit] loadFixtureDetail parsed → '
                'leagueId=${safeFixture.leagueId} '
                'homeTeamId=${safeFixture.homeTeamId} '
                'awayTeamId=${safeFixture.awayTeamId} '
                'season=${safeFixture.season}');

            if (!_isClosed) emit(state.copyWith(fixture: safeFixture, isLoadingTab: false));
          }
        } catch (e) {
          debugPrint('[MatchDetailCubit] ⚠️ loadFixtureDetail parse error: $e');
          if (!_isClosed) emit(state.copyWith(isLoadingTab: false));
        }
      } else {
        debugPrint('[MatchDetailCubit] ⚠️ loadFixtureDetail HTTP ${response?.statusCode}');
        if (!_isClosed) emit(state.copyWith(isLoadingTab: false));
      }

      loadActiveTab();
    } catch (e) {
      if (_isClosed) return;
      debugPrint('[MatchDetailCubit] ⚠️ loadFixtureDetail error: $e');
      emit(state.copyWith(isLoadingTab: false));
      loadActiveTab();
    }
  }

  FixtureModel _restoreOriginalIds(FixtureModel parsed) {
    final leagueId   = (parsed.leagueId?.isNotEmpty   == true) ? parsed.leagueId   : _originalLeagueId;
    final homeTeamId = (parsed.homeTeamId?.isNotEmpty == true) ? parsed.homeTeamId : _originalHomeTeamId;
    final awayTeamId = (parsed.awayTeamId?.isNotEmpty == true) ? parsed.awayTeamId : _originalAwayTeamId;
    final season     = (parsed.season?.isNotEmpty     == true) ? parsed.season     : _originalSeason;

    if (leagueId == parsed.leagueId &&
        homeTeamId == parsed.homeTeamId &&
        awayTeamId == parsed.awayTeamId &&
        season == parsed.season) {
      return parsed;
    }

    return FixtureModel(
      fixtureId:  parsed.fixtureId,
      date:       parsed.date,
      timestamp:  parsed.timestamp,
      status:     parsed.status,
      league:     parsed.league,
      teams:      parsed.teams,
      score:      parsed.score,
      venue:      parsed.venue,
      referee:    parsed.referee,
      season:     season,
      leagueId:   leagueId,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
    );
  }

  void changeTab(String tabKey) {
    if (_isClosed) return;
    emit(state.copyWith(activeTab: tabKey));
    loadActiveTab();
  }

  Future<void> loadActiveTab() async {
    if (_isClosed) return;
    final fixture = state.fixture;
    if (fixture == null) return;
    if (state.cache.containsKey(state.activeTab)) return;

    emit(state.copyWith(isLoadingTab: true, clearError: true));

    try {
      final newCache = Map<String, dynamic>.from(state.cache);
      String? url;

      switch (state.activeTab) {
        case 'details':
          url = '$apiBase/fixture/${fixture.fixtureId}/events/';
          break;
        case 'statistics':
          url = '$apiBase/fixture/${fixture.fixtureId}/stats/';
          break;
        case 'lineups':
          url = '$apiBase/fixture/${fixture.fixtureId}/lineups/';
          break;
        case 'standings':
          final leagueId = (_originalLeagueId?.isNotEmpty == true)
              ? _originalLeagueId!
              : (fixture.leagueId ?? '');
          final season = (_originalSeason?.isNotEmpty == true)
              ? _originalSeason!
              : (fixture.season ?? '');
          if (leagueId.isNotEmpty && season.isNotEmpty) {
            url = '$apiBase/standings/$leagueId/$season/';
            debugPrint('[MatchDetailCubit] Standings URL: $url');
          } else {
            debugPrint('[MatchDetailCubit] ⚠️ Standings skipped — '
                'leagueId="$leagueId" season="$season"');
          }
          break;
        case 'h2h':
          final homeId = (_originalHomeTeamId?.isNotEmpty == true)
              ? _originalHomeTeamId!
              : (fixture.homeTeamId ?? '');
          final awayId = (_originalAwayTeamId?.isNotEmpty == true)
              ? _originalAwayTeamId!
              : (fixture.awayTeamId ?? '');
          if (homeId.isNotEmpty && awayId.isNotEmpty) {
            url = '$apiBase/h2h/$homeId/$awayId/';
            debugPrint('🔍 [MatchDetailCubit] H2H URL: $url');
          } else {
            debugPrint('⚠️ [MatchDetailCubit] H2H skipped — '
                'homeTeamId="$homeId" awayTeamId="$awayId"');
          }
          break;
      }

      if (url != null) {
        final response = await _fetchWithAutoRetry(url);
        if (_isClosed) return;
        if (response != null && response.statusCode == 200) {
          final rawBody = response.body;
          // 🆕 পুরো রেসপন্স প্রিন্ট করুন (Logcat এ দেখতে print ব্যবহার করছি)
          print('📄 [H2H Raw] FULL BODY:\n$rawBody');
          
          final parsed = _resilientParseJsonList(rawBody, '${state.activeTab}-${fixture.fixtureId}');
          debugPrint('📊 [H2H Parsed] count=${parsed.length}');
          if (parsed.isNotEmpty) {
            debugPrint('📊 [H2H Parsed] First item: ${parsed[0]}');
          }
          newCache[state.activeTab] = parsed;
        } else {
          debugPrint('❌ [H2H] HTTP status: ${response?.statusCode}');
          newCache[state.activeTab] = <dynamic>[];
        }
      }

      if (_isClosed) return;
      emit(state.copyWith(cache: newCache, isLoadingTab: false));
    } catch (e) {
      if (_isClosed) return;
      debugPrint('❌ [loadActiveTab] Error: $e');
      final newCache = Map<String, dynamic>.from(state.cache);
      newCache[state.activeTab] = <dynamic>[];
      emit(state.copyWith(cache: newCache, isLoadingTab: false));
    }
  }
}