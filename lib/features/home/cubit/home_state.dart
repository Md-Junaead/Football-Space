import 'package:flutter/foundation.dart';
import 'package:football_space/models/fixture_model.dart';

// ═══════════════════════════════════════════════════════════════
// HOME STATE — Pure immutable data class.
// No logic. No Flutter deps. Only data.
//
// Pagination fields added (DRF limit/offset support):
//   hasMore       — true if API "next" is not null
//   isLoadingMore — true when fetching next page (not first load)
//   nextUrl       — full "next" URL from DRF response, ready to call
// ═══════════════════════════════════════════════════════════════
@immutable
class HomeState {
  final List<FixtureModel> fixtures;
  final bool isLoading;
  final bool isLoadingMore;   // ← NEW: loading next page (bottom spinner)
  final bool hasMore;         // ← NEW: is there a "next" page?
  final String? nextUrl;      // ← NEW: full DRF "next" URL
  final String? error;
  final bool liveOnly;
  final String? selectedDate;
  final int retryAttempt;

  const HomeState({
    this.fixtures = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.nextUrl,
    this.error,
    this.liveOnly = true,
    this.selectedDate,
    this.retryAttempt = 0,
  });

  HomeState copyWith({
    List<FixtureModel>? fixtures,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? nextUrl,
    bool clearNextUrl = false,
    String? error,
    bool? liveOnly,
    String? selectedDate,
    bool clearSelectedDate = false,
    int? retryAttempt,
  }) {
    return HomeState(
      fixtures: fixtures ?? this.fixtures,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextUrl: clearNextUrl ? null : (nextUrl ?? this.nextUrl),
      error: error,
      liveOnly: liveOnly ?? this.liveOnly,
      selectedDate: clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      retryAttempt: retryAttempt ?? this.retryAttempt,
    );
  }
}