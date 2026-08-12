import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_live_score/config/app_colors.dart';
import 'package:football_live_score/core/routes/app_routes.dart';
import 'package:football_live_score/features/home/cubit/home_cubit.dart';
import 'package:football_live_score/features/home/cubit/home_state.dart';
import 'package:football_live_score/models/fixture_model.dart';
import 'package:football_live_score/features/home/widgets/date_bar.dart';

// ═══════════════════════════════════════════════════════════════
// HOME SCREEN (View)
//
// MVVM role: View
//   - Reads state from HomeCubit (ViewModel) via BlocBuilder
//   - Calls methods on HomeCubit — never runs logic itself
//   - Navigation via AppRouter (named routes only)
//   - Owns ScrollController for pagination trigger
//
// NOTE: HomeCubit is provided by AppShell → IndexedStack,
// so do NOT wrap this in another BlocProvider here.
//
// NOTE: Notifications feature is temporarily disabled — the bell
// icon in the nav bar is kept for design consistency but is now a
// static placeholder (shows a "Coming Soon" message on tap) instead
// of being wired to NotificationCubit.
// ═══════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ScrollController — detects when user reaches bottom of list
  // to trigger loadMoreFixtures() from HomeCubit.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Always dispose controllers — prevents memory leaks
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // Fires when user scrolls within 200px of bottom.
  // Delegates entirely to HomeCubit — zero logic here.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      context.read<HomeCubit>().loadMoreFixtures();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) => _buildNavBar(state, context),
            ),
            const SizedBox(height: 12),
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) => DateBar(
                selectedDate: state.selectedDate,
                onDateSelected: (date) => context.read<HomeCubit>().selectDate(date),
              ),
            ),
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  if (state.isLoading) return _buildLoadingState(state);
                  if (state.error != null) return _buildErrorState(state);

                  final filtered = state.liveOnly
                      ? state.fixtures.where((f) => f.isLive || (f.isNS && !f.isProbablyFinished)).toList()
                      : state.fixtures;

                  if (filtered.isEmpty) return _buildEmptyState(state);

                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      ..._buildLeagueGroups(filtered, context),
                      // Pagination footer — spinner or "all loaded" message
                      _buildPaginationFooter(state),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pagination Footer ─────────────────────────────────────────

  Widget _buildPaginationFooter(HomeState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
              SizedBox(height: 10),
              Text(
                'Loading more matches...',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    // Only show "all loaded" in date mode where pagination applies
    if (!state.hasMore && state.fixtures.isNotEmpty && state.selectedDate != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'All ${state.fixtures.length} matches loaded',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted2),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ─── Nav Bar ───────────────────────────────────────────────────

  Widget _buildNavBar(HomeState state, BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Football Space',
              style: TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
          _buildNotificationBell(context),
        ],
      ),
    );
  }

  // ─── Notification Bell (placeholder — feature disabled) ────────
  //
  // Same visual design as before (kept for UI consistency), but no
  // longer wired to NotificationCubit / unread-count state. Tapping
  // it simply shows a "Coming Soon" message.
  Widget _buildNotificationBell(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications coming soon'),
            backgroundColor: AppColors.surface2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.notifications_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  // ─── League Groups ─────────────────────────────────────────────

  List<Widget> _buildLeagueGroups(List<FixtureModel> fixtures, BuildContext context) {
    final grouped = <String, List<FixtureModel>>{};
    for (var f in fixtures) {
      final key = '${f.league['id'] ?? 'u'}-${f.league['name']?.toString() ?? 'Unknown'}';
      grouped.putIfAbsent(key, () => []).add(f);
    }

    return grouped.entries.map((entry) {
      final leagueFixtures = entry.value;
      final leagueData = leagueFixtures.first.league;
      final leagueName = leagueData['name']?.toString() ?? 'Unknown';
      final leagueCountry = leagueData['country']?.toString() ?? '';
      final leagueRound = leagueData['round']?.toString() ?? '';

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // League header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: AppColors.surface2.withOpacity(0.3),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  _buildLeagueLogo(leagueData),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(leagueName,
                            style: const TextStyle(
                                fontFamily: 'Barlow Condensed',
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        Text(
                            '$leagueCountry · ${leagueFixtures.length} match${leagueFixtures.length > 1 ? 'es' : ''}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted2)),
                      ],
                    ),
                  ),
                  if (leagueRound.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(leagueRound,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                    ),
                ],
              ),
            ),
            ...leagueFixtures.map((f) => _buildFixtureCard(f, context)),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildLeagueLogo(Map<String, dynamic> league) {
    final logo = league['logo']?.toString() ?? '';
    if (logo.isNotEmpty) {
      return CircleAvatar(
          backgroundImage: NetworkImage(logo),
          radius: 14,
          backgroundColor: AppColors.surface2);
    }
    return CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.surface2,
        child: Text(FixtureModel.teamInitials(league),
            style: const TextStyle(
                fontFamily: 'Barlow Condensed',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted)));
  }

  // ─── Fixture Card ──────────────────────────────────────────────

  Widget _buildFixtureCard(FixtureModel f, BuildContext context) {
    final home = f.homeTeam;
    final away = f.awayTeam;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        // ✅ ROUTING UPDATE: Now uses named route via AppRouter
        // Before (old): Navigator.push(context, MaterialPageRoute(builder: ...))
        // After (new):  Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: f)
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.matchDetail,
          arguments: f, // FixtureModel passed as arguments
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(f),
                  Flexible(
                      child: Text(f.venue['name']?.toString() ?? '',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted2),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildTeamSide(home, alignLeft: true)),
                  _buildScoreOrTime(f),
                  Expanded(child: _buildTeamSide(away, alignLeft: false)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSide(Map<String, dynamic> team, {required bool alignLeft}) {
    final logo = team['logo']?.toString() ?? '';
    final name = team['name']?.toString() ?? '';
    final logoWidget = _buildTeamLogo(team, logo);
    final nameWidget = Text(name,
        style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
        textAlign: alignLeft ? TextAlign.left : TextAlign.right,
        maxLines: 2,
        overflow: TextOverflow.ellipsis);

    if (alignLeft) {
      return Row(children: [logoWidget, const SizedBox(width: 8), Flexible(child: nameWidget)]);
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [Flexible(child: nameWidget), const SizedBox(width: 8), logoWidget]);
  }

  Widget _buildTeamLogo(Map<String, dynamic> team, String logo) {
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: AppColors.surface2,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border)),
      child: logo.isNotEmpty
          ? ClipOval(
              child: Image.network(logo,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                      child: Text(FixtureModel.teamInitials(team),
                          style: const TextStyle(
                              fontFamily: 'Barlow Condensed',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted)))))
          : Center(
              child: Text(FixtureModel.teamInitials(team),
                  style: const TextStyle(
                      fontFamily: 'Barlow Condensed',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted))),
    );
  }

  // ─── Status Badge ──────────────────────────────────────────────

  Widget _buildStatusBadge(FixtureModel f) {
    if (f.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.live.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.live.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: AppColors.live, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text("LIVE ${f.status['elapsed'] ?? ''}'",
              style: const TextStyle(
                  color: AppColors.live, fontWeight: FontWeight.w800, fontSize: 11))
        ]),
      );
    }

    if (f.isProbablyFinished) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999)),
          child: const Text('FT',
              style: TextStyle(
                  color: AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 11)));
    }

    if (f.isNS) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.accent.withOpacity(0.2))),
          child: Text(f.kickoffTime,
              style: const TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 11)));
    }

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.textMuted.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999)),
        child: Text(f.status['short'] ?? '',
            style: const TextStyle(
                color: AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 11)));
  }

  // ─── Score or Time ─────────────────────────────────────────────

  Widget _buildScoreOrTime(FixtureModel f) {
    if (f.isProbablyFinished) {
      final homeScore = f.score['home'] ?? 0;
      final awayScore = f.score['away'] ?? 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: AppColors.scoreBoxBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withOpacity(0.2))),
        child: Column(children: [
          Text('$homeScore - $awayScore',
              style: const TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 2)),
          const SizedBox(height: 2),
          const Text('FT',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        ]),
      );
    }

    if (f.isLive) {
      final homeScore = f.score['home'] ?? 0;
      final awayScore = f.score['away'] ?? 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: AppColors.live.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.live.withOpacity(0.25))),
        child: Column(children: [
          Text('$homeScore - $awayScore',
              style: const TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 2)),
          LiveMatchTimer(fixture: f),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.scoreBoxBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withOpacity(0.15))),
      child: Column(children: [
        Text(f.kickoffTime,
            style: const TextStyle(
                fontFamily: 'Barlow Condensed',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.accent,
                letterSpacing: 1)),
        const SizedBox(height: 2),
        const Text('KO',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
      ]),
    );
  }

  // ─── Loading State ─────────────────────────────────────────────

  Widget _buildLoadingState(HomeState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            state.retryAttempt > 0
                ? 'Retrying (${state.retryAttempt}/5)...'
                : 'Loading fixtures...',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Error State ───────────────────────────────────────────────

  Widget _buildErrorState(HomeState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('Failed to load fixtures',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(state.error ?? 'Unknown error',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.bg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────

  Widget _buildEmptyState(HomeState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_soccer, size: 56, color: AppColors.border),
          const SizedBox(height: 16),
          const Text('No matches found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            state.liveOnly
                ? 'No live matches right now.\nTry selecting a date.'
                : 'No matches on this date.',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LIVE MATCH TIMER — Self-contained, deferred start
// Only shown for truly LIVE or truly UPCOMING matches
// ═══════════════════════════════════════════════════════════════
class LiveMatchTimer extends StatefulWidget {
  final FixtureModel fixture;

  const LiveMatchTimer({super.key, required this.fixture});

  @override
  State<LiveMatchTimer> createState() => _LiveMatchTimerState();
}

class _LiveMatchTimerState extends State<LiveMatchTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startTimer();
    });
  }

  @override
  void didUpdateWidget(covariant LiveMatchTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixture.fixtureId != widget.fixture.fixtureId) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fixture;
    String timerText = '';
    Color timerColor = AppColors.live;

    if (f.isNS && f.date != null) {
      final diff =
          f.date!.toUtc().millisecondsSinceEpoch - DateTime.now().toUtc().millisecondsSinceEpoch;
      if (diff <= 0) {
        timerText = 'Starting...';
        timerColor = AppColors.live;
      } else {
        final h = diff ~/ 3600000;
        final m = (diff % 3600000) ~/ 60000;
        final s = (diff % 60000) ~/ 1000;
        timerText =
            'Starts in ${h > 0 ? '${h}h ' : ''}${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
        timerColor = AppColors.accent;
      }
    } else if (f.isLive && f.date != null) {
      final kickoff = f.date!.toUtc().millisecondsSinceEpoch;
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      int elapsedMs = now - kickoff;
      final statusShort = f.status['short']?.toString() ?? '';

      if (statusShort == 'HT') {
        elapsedMs = 45 * 60 * 1000;
      } else if (statusShort == '2H') {
        final secondHalfStart = kickoff + (45 + 15) * 60 * 1000;
        elapsedMs = now > secondHalfStart
            ? 45 * 60 * 1000 + (now - secondHalfStart)
            : 45 * 60 * 1000;
      } else if (statusShort == 'ET') {
        final extraTimeStart = kickoff + (90 + 15) * 60 * 1000;
        elapsedMs = now > extraTimeStart
            ? 90 * 60 * 1000 + (now - extraTimeStart)
            : 90 * 60 * 1000;
      }

      final totalSecs = (elapsedMs / 1000).floor().clamp(0, 99999);
      final mins = totalSecs ~/ 60;
      final secs = totalSecs % 60;
      timerText = '$mins:${secs.toString().padLeft(2, '0')}';
      timerColor = AppColors.live;
    }

    if (timerText.isEmpty) return const SizedBox.shrink();

    return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (f.isLive)
              Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 5),
                  decoration:
                      const BoxDecoration(color: AppColors.live, shape: BoxShape.circle)),
            Text(timerText,
                style: TextStyle(
                    fontFamily: 'Barlow Condensed',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: timerColor,
                    letterSpacing: 1)),
          ],
        ));
  }
}
