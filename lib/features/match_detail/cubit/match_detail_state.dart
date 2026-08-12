import 'package:flutter/foundation.dart';
import 'package:football_space/models/fixture_model.dart';

// ═══════════════════════════════════════════════════════════════
// MATCH DETAIL STATE — Pure immutable data class.
// No logic. No Flutter deps. Only data.
// ═══════════════════════════════════════════════════════════════
@immutable
class MatchDetailState {
  final FixtureModel? fixture;
  final String activeTab;
  final Map<String, dynamic> cache;
  final bool isLoadingTab;
  final String? error;

  const MatchDetailState({
    this.fixture,
    this.activeTab = 'details',
    this.cache = const {},
    this.isLoadingTab = false,
    this.error,
  });

  MatchDetailState copyWith({
    FixtureModel? fixture,
    String? activeTab,
    Map<String, dynamic>? cache,
    bool? isLoadingTab,
    String? error,
    bool clearError = false,
  }) {
    return MatchDetailState(
      fixture: fixture ?? this.fixture,
      activeTab: activeTab ?? this.activeTab,
      cache: cache ?? this.cache,
      isLoadingTab: isLoadingTab ?? this.isLoadingTab,
      error: clearError ? null : (error ?? this.error),
    );
  }
}