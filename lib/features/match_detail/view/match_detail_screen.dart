import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_live_score/config/app_colors.dart';
import 'package:football_live_score/features/match_detail/cubit/match_detail_cubit.dart';
import 'package:football_live_score/features/match_detail/cubit/match_detail_state.dart';
import 'package:football_live_score/models/fixture_model.dart';

// ═══════════════════════════════════════════════════════════════
// MATCH DETAIL SCREEN (View)
//
// MVVM role: View
//   - BlocProvider is set up by AppRouter (not here)
//   - Reads MatchDetailState, calls MatchDetailCubit methods only
//   - Navigation: back = Navigator.pop(context)
// ═══════════════════════════════════════════════════════════════
class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({super.key});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<MatchDetailCubit, MatchDetailState>(
          builder: (context, state) {
            final fixture = state.fixture;
            if (fixture == null) {
              return const Center(
                  child: Text('No match selected',
                      style: TextStyle(color: AppColors.textSecondary)));
            }

            if (state.error != null && !state.isLoadingTab) {
              return Column(
                children: [
                  _buildNavBar(fixture),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            const Text('Failed to load details',
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
                              onPressed: () => context
                                  .read<MatchDetailCubit>()
                                  .loadFixtureDetail(fixture.fixtureId),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.bg,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildNavBar(fixture),
                _buildMatchHeader(fixture),
                _buildTabs(state.activeTab, context),
                Expanded(
                  child: state.isLoadingTab
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.accent))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          child: _buildTabContent(fixture, state.activeTab, state.cache),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Nav Bar ───────────────────────────────────────────────────

  Widget _buildNavBar(FixtureModel fixture) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border)),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Text('Match Details',
                style: TextStyle(
                    fontFamily: 'Barlow Condensed',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            Text(fixture.league['name'] ?? '',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ])),
          const SizedBox(width: 54),
        ],
      ),
    );
  }

  // ─── Match Header ──────────────────────────────────────────────

  Widget _buildMatchHeader(FixtureModel f) {
    final home = f.homeTeam;
    final away = f.awayTeam;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.heroGradientStart,
              AppColors.heroGradientMid,
              AppColors.heroGradientEnd,
            ]),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildTeamBlock(home)),
            _buildScoreBlock(f),
            Expanded(child: _buildTeamBlock(away, alignRight: true)),
          ],
        ),
      ]),
    );
  }

  Widget _buildTeamBlock(Map<String, dynamic> team, {bool alignRight = false}) {
    final logo = team['logo']?.toString() ?? '';
    final name = team['name']?.toString() ?? '';

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2)),
          child: logo.isNotEmpty
              ? ClipOval(
                  child: Image.network(logo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                          child: Text(FixtureModel.teamInitials(team),
                              style: const TextStyle(
                                  fontFamily: 'Barlow Condensed',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textMuted)))))
              : Center(
                  child: Text(FixtureModel.teamInitials(team),
                      style: const TextStyle(
                          fontFamily: 'Barlow Condensed',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMuted))),
        ),
        const SizedBox(height: 10),
        Text(name,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildScoreBlock(FixtureModel f) {
    final homeScore = f.score['home'] ?? 0;
    final awayScore = f.score['away'] ?? 0;
    final statusShort = f.status['short'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
          color: AppColors.scoreBoxBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: f.isLive
                  ? AppColors.live.withOpacity(0.4)
                  : AppColors.accent.withOpacity(0.2))),
      child: Column(children: [
        Text('$homeScore - $awayScore',
            style: const TextStyle(
                fontFamily: 'Barlow Condensed',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 3)),
        const SizedBox(height: 4),
        if (f.isLive)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration:
                    const BoxDecoration(color: AppColors.live, shape: BoxShape.circle)),
            Text("LIVE ${f.status['elapsed'] ?? ''}'",
                style: const TextStyle(
                    color: AppColors.live, fontWeight: FontWeight.w800, fontSize: 12))
          ])
        else
          Text(statusShort,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
      ]),
    );
  }

  // ─── Tabs ──────────────────────────────────────────────────────

  Widget _buildTabs(String activeTab, BuildContext context) {
    const tabs = [
      {'key': 'details', 'label': 'Events'},
      {'key': 'statistics', 'label': 'Stats'},
      {'key': 'lineups', 'label': 'Lineup'},
      {'key': 'standings', 'label': 'Table'},
      {'key': 'h2h', 'label': 'H2H'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.bg.withOpacity(0.97),
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final isActive = activeTab == t['key'];
            return GestureDetector(
              onTap: () =>
                  context.read<MatchDetailCubit>().changeTab(t['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                    color: isActive ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: isActive ? AppColors.accent : AppColors.border)),
                child: Text(t['label'] as String,
                    style: TextStyle(
                        fontFamily: 'Barlow Condensed',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isActive ? AppColors.bg : AppColors.textSecondary)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Tab Content ───────────────────────────────────────────────

  Widget _buildTabContent(
      FixtureModel f, String activeTab, Map<String, dynamic> cache) {
    switch (activeTab) {
      case 'details':
        return Column(children: [
          _buildEvents(cache['details'] ?? []),
          const SizedBox(height: 12),
          _buildInfoCard(f)
        ]);
      case 'statistics':
        return _buildStats(cache['statistics'] ?? []);
      case 'lineups':
        return _buildLineups(cache['lineups'] ?? []);
      case 'standings':
        return _buildStandings(cache['standings'] ?? []);
      case 'h2h':
        return _buildH2H(cache['h2h'] ?? []);
      default:
        return const SizedBox();
    }
  }

  // ─── Section Card ──────────────────────────────────────────────

  Widget _sectionCard({required String title, required Widget child, Widget? headerExtra}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                      color: AppColors.accent, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'Barlow Condensed',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const Spacer(),
              if (headerExtra != null) headerExtra
            ])),
        const SizedBox(height: 8),
        child
      ]),
    );
  }

  // ─── Events ────────────────────────────────────────────────────

  Widget _buildEvents(List<dynamic> events) {
    if (events.isEmpty) {
      return _sectionCard(
          title: 'Match Events',
          child: _buildEmpty('No Events Yet', 'Events will appear when the match starts'));
    }
    return _sectionCard(
        title: 'Match Events',
        headerExtra: Text('${events.length}',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
        child: Column(
            children: events.map<Widget>((e) {
          final minute = "${e['time']?['elapsed'] ?? e['minute'] ?? ''}'";
          final extra = e['time']?['extra'] ?? e['extra'] ?? '';
          final extraStr = extra.toString().isNotEmpty ? '+$extra' : '';
          final type = e['type'] ?? '';
          final detail = e['detail'] ?? '';
          final playerName = e['player'] is Map
              ? (e['player']['name'] ?? '')
              : (e['player']?.toString() ?? '');
          final assistName = e['assist'] is Map ? (e['assist']['name'] ?? '') : '';
          final teamName = e['team'] is Map
              ? (e['team']['name'] ?? '')
              : (e['team']?.toString() ?? '');
          final iconAndColor = _eventVisual(type, detail);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.border.withOpacity(0.5)))),
            child: Row(children: [
              Container(
                  width: 38,
                  alignment: Alignment.center,
                  child: Text('$minute$extraStr',
                      style: const TextStyle(
                          fontFamily: 'Barlow Condensed',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted))),
              const SizedBox(width: 8),
              Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: iconAndColor.$2.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child:
                      Center(child: Text(iconAndColor.$1, style: const TextStyle(fontSize: 16)))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(playerName.isNotEmpty ? playerName : 'Unknown',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                if (assistName.isNotEmpty)
                  Text('Assist: $assistName',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text('$teamName · $type${detail.isNotEmpty ? ' · $detail' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ])),
            ]),
          );
        }).toList()));
  }

  (String, Color) _eventVisual(String? type, String? detail) {
    final v = '${type ?? ''} ${detail ?? ''}'.toLowerCase();
    if (v.contains('goal')) return ('⚽', AppColors.gold);
    if (v.contains('yellow')) return ('🟨', AppColors.yellow);
    if (v.contains('red')) return ('🟥', AppColors.live);
    if (v.contains('subst')) return ('🔄', AppColors.purple);
    if (v.contains('penalty')) return ('🎯', AppColors.gold);
    return ('•', AppColors.textMuted);
  }

  // ─── Info Card ─────────────────────────────────────────────────

  Widget _buildInfoCard(FixtureModel f) {
    final items = [
      ('League', f.league['name'] ?? '-'),
      ('Round', f.round),
      ('Country', f.league['country'] ?? '-'),
      ('Season', f.season ?? '-'),
      ('Venue', f.venue['name'] ?? '-'),
      ('City', f.venue['city'] ?? '-'),
      ('Kick Off', f.date != null ? f.date!.toLocal().toString().substring(0, 16) : '-'),
      ('Referee', f.referee ?? '-'),
    ];
    return _sectionCard(
        title: 'Match Info',
        child: Column(
            children: items
                .map((item) => Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: AppColors.border.withOpacity(0.5)))),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.$1,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600)),
                            Flexible(
                                child: Text(item.$2,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppColors.textPrimary),
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis))
                          ]),
                    ))
                .toList()));
  }

  // ─── Stats ─────────────────────────────────────────────────────

  Widget _buildStats(List<dynamic> stats) {
    if (stats.isEmpty || stats.length < 2) {
      return _sectionCard(
          title: 'Statistics',
          child: _buildEmpty(
              'No Stats Available', 'Stats will appear once the match starts'));
    }

    final homeTeamData = stats[0];
    final awayTeamData = stats[1];
    final homeTeam = homeTeamData['team'] is Map ? homeTeamData['team'] : {};
    final awayTeam = awayTeamData['team'] is Map ? awayTeamData['team'] : {};
    final homeStats = homeTeamData['statistics'] ?? [];
    final awayStats = awayTeamData['statistics'] ?? [];

    return _sectionCard(
        title: 'Match Stats',
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(children: [
                Expanded(
                    child: Text(homeTeam['name'] ?? 'Home',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statHomeBar),
                        textAlign: TextAlign.left)),
                Expanded(
                    child: Text(awayTeam['name'] ?? 'Away',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statAwayBar),
                        textAlign: TextAlign.right)),
              ])),
          const Divider(color: AppColors.border, height: 1),
          ...List.generate(homeStats.length, (i) {
            final type = homeStats[i]['type'] ?? '';
            return _buildDualStatRow(
                type, homeStats[i]['value'], awayStats[i]?['value']);
          }),
        ]));
  }

  Widget _buildDualStatRow(String type, dynamic homeVal, dynamic awayVal) {
    int parseVal(v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString().replaceAll('%', '')) ?? 0;
    }

    final homeInt = parseVal(homeVal);
    final awayInt = parseVal(awayVal);
    final total = homeInt + awayInt;
    final homePct = total == 0 ? 0.5 : homeInt / total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.border.withOpacity(0.4)))),
      child: Column(children: [
        Row(children: [
          SizedBox(
              width: 42,
              child: Text(homeVal?.toString() ?? '0',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.right)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(type,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5),
                  textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          SizedBox(
              width: 42,
              child: Text(awayVal?.toString() ?? '0',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.left)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                      height: 5,
                      child: Stack(alignment: Alignment.centerRight, children: [
                        Container(
                            decoration: BoxDecoration(
                                color: AppColors.statHomeBg,
                                borderRadius: BorderRadius.circular(3))),
                        FractionallySizedBox(
                            widthFactor: homePct.clamp(0.05, 1.0),
                            child: Container(
                                decoration: BoxDecoration(
                                    color: AppColors.statHomeBar,
                                    borderRadius: BorderRadius.circular(3))))
                      ])))),
          const SizedBox(width: 3),
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                      height: 5,
                      child: Stack(alignment: Alignment.centerLeft, children: [
                        Container(
                            decoration: BoxDecoration(
                                color: AppColors.statAwayBg,
                                borderRadius: BorderRadius.circular(3))),
                        FractionallySizedBox(
                            widthFactor: (1 - homePct).clamp(0.05, 1.0),
                            child: Container(
                                decoration: BoxDecoration(
                                    color: AppColors.statAwayBar,
                                    borderRadius: BorderRadius.circular(3))))
                      ])))),
        ]),
      ]),
    );
  }

  // ─── Lineups ───────────────────────────────────────────────────

  Widget _buildLineups(List<dynamic> lineups) {
    if (lineups.isEmpty) {
      return _sectionCard(
          title: 'Lineup',
          child:
              _buildEmpty('No Lineup Available', 'Lineups usually appear before kick-off'));
    }

    return Column(children: [
      _buildFormationPitch(lineups),
      const SizedBox(height: 12),
      ...lineups.map<Widget>((team) {
        final teamName =
            team['team'] is Map ? (team['team']['name'] ?? '') : '';
        final formation = team['formation'] ?? '';
        final startXI = team['startXI'] ?? [];
        final subs = team['substitutes'] ?? [];
        final coach =
            team['coach'] is Map ? (team['coach']['name'] ?? '') : '';

        return _sectionCard(
            title: teamName,
            headerExtra: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.accent.withOpacity(0.25))),
                child: Text(formation,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (coach.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(children: [
                      const Icon(Icons.manage_accounts,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(coach,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary))
                    ])),
              ...startXI.map<Widget>((p) => _buildPlayerRow(p, isSub: false)),
              if (subs.isNotEmpty) ...[
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Text('Substitutes',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted.withOpacity(0.8)))),
                ...subs.map<Widget>((p) => _buildPlayerRow(p, isSub: true)),
              ]
            ]));
      }),
    ]);
  }

  Widget _buildFormationPitch(List<dynamic> lineups) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.pitchGreen1,
              AppColors.pitchGreen2,
              AppColors.pitchGreen1
            ]),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Stack(alignment: Alignment.center, children: [
        Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.06), width: 2))),
        Positioned(
            left: 0,
            right: 0,
            child: Container(height: 1, color: Colors.white.withOpacity(0.06))),
        Row(children: [
          ...lineups.map<Widget>((l) {
            final team = l['team'] is Map
                ? l['team'] as Map<String, dynamic>
                : <String, dynamic>{};
            final formation = l['formation'] ?? '-';
            final logo = team['logo']?.toString() ?? '';
            final name = team['name']?.toString() ?? '';
            return Expanded(
                child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      color: AppColors.surface2,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border)),
                  child: logo.isNotEmpty
                      ? ClipOval(
                          child: Image.network(logo,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                      FixtureModel.teamInitials(team),
                                      style: const TextStyle(
                                          fontFamily: 'Barlow Condensed',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textMuted)))))
                      : Center(
                          child: Text(FixtureModel.teamInitials(team),
                              style: const TextStyle(
                                  fontFamily: 'Barlow Condensed',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textMuted))),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      Text(formation,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700)),
                    ])),
              ]),
            ));
          }),
        ]),
      ]),
    );
  }

  Widget _buildPlayerRow(dynamic playerData, {required bool isSub}) {
    final player = playerData['player'] is Map
        ? playerData['player'] as Map<String, dynamic>
        : <String, dynamic>{};
    final name = player['name']?.toString() ?? '';
    final number = player['number']?.toString() ?? '';
    final pos = player['pos']?.toString() ?? '';
    final photo = player['photo']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          border: Border(
              bottom:
                  BorderSide(color: AppColors.border.withOpacity(0.5)))),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: isSub
                  ? AppColors.surface2
                  : AppColors.accent.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSub
                      ? AppColors.border
                      : AppColors.accent.withOpacity(0.3))),
          child: Center(
              child: Text(number,
                  style: TextStyle(
                      fontFamily: 'Barlow Condensed',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isSub ? AppColors.textMuted : AppColors.accent))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isSub ? AppColors.textMuted : AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(6)),
          child: Text(pos,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted)),
        ),
      ]),
    );
  }

  // ─── Standings ─────────────────────────────────────────────────

Widget _buildStandings(List<dynamic> standings) {
  if (standings.isEmpty) {
    return _sectionCard(
      title: 'League Table',
      child: _buildEmpty('No Standings Available', 'Table data not available'),
    );
  }

  // ─── সঠিকভাবে গ্রুপগুলো বের করা ──────────────────────────
  List<List<dynamic>> groups = [];
  String leagueName = '';

  try {
    final firstEntry = standings.isNotEmpty ? standings[0] : null;
    if (firstEntry is Map) {
      final league = firstEntry['league'];
      if (league is Map) {
        leagueName = league['name']?.toString() ?? 'League Table';
        final rawStandings = league['standings'];
        if (rawStandings is List) {
          for (var g in rawStandings) {
            if (g is List) {
              groups.add(g);
            }
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Error parsing standings: $e');
  }

  // ─── ফলব্যাক (যদি উপরের কাজ না করে) ──────────────────────
  if (groups.isEmpty && standings.isNotEmpty) {
    if (standings[0] is List) {
      groups.add(standings[0] as List);
    } else {
      groups.add(standings);
    }
  }

  if (groups.isEmpty) {
    return _sectionCard(
      title: 'League Table',
      child: _buildEmpty('No Standings Available', 'Table data not available'),
    );
  }

  // ─── UI তৈরি ────────────────────────────────────────────────
  return _sectionCard(
    title: leagueName,
    child: Column(
      children: [
        // টেবিল হেডার
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Row(
            children: [
              const SizedBox(width: 28),
              const Expanded(
                  child: Text('Team',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted))),
              ...['P', 'W', 'D', 'L', 'GD', 'PTS'].map((h) => SizedBox(
                  width: 30,
                  child: Text(h,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted),
                      textAlign: TextAlign.center))),
            ],
          ),
        ),
        const Divider(color: AppColors.border, height: 1),

        // ─── প্রতিটি গ্রুপের জন্য লুপ ──────────────────────
        for (int gIndex = 0; gIndex < groups.length; gIndex++)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // গ্রুপ হেডার (Group A, Group B ...)
              if (groups.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    _extractGroupName(groups[gIndex], gIndex),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        letterSpacing: 0.5),
                  ),
                ),

              // গ্রুপের প্রতিটি টিমের সারি
              ...groups[gIndex].map<Widget>((row) {
                if (row is! Map) return const SizedBox.shrink();
                final team = row['team'] is Map ? row['team'] : {};
                final all = row['all'] is Map ? row['all'] : {};
                final rank = row['rank']?.toString() ?? '';
                final pts = row['points']?.toString() ?? '0';
                final gd = row['goalsDiff']?.toString() ?? '0';
                final played = all['played']?.toString() ?? '0';
                final win = all['win']?.toString() ?? '0';
                final draw = all['draw']?.toString() ?? '0';
                final lose = all['lose']?.toString() ?? '0';
                final logo = team['logo']?.toString() ?? '';
                final name = team['name']?.toString() ?? '';
                final gdInt = int.tryParse(gd) ?? 0;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.border.withOpacity(0.4)))),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 28,
                          child: Text(rank,
                              style: const TextStyle(
                                  fontFamily: 'Barlow Condensed',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textMuted),
                              textAlign: TextAlign.center)),
                      logo.isNotEmpty
                          ? Image.network(logo,
                              width: 20,
                              height: 20,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(width: 20, height: 20))
                          : const SizedBox(width: 20, height: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(name,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis)),
                      ...[played, win, draw, lose, gdInt >= 0 ? '+$gd' : gd, pts]
                          .map((v) => SizedBox(
                              width: 30,
                              child: Text(v,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: v == pts
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: v == pts
                                          ? AppColors.accent
                                          : AppColors.textSecondary),
                                  textAlign: TextAlign.center))),
                    ],
                  ),
                );
              }).toList(),

              if (gIndex < groups.length - 1)
                const Divider(color: AppColors.border, height: 8, thickness: 1.5),
            ],
          ),
      ],
    ),
  );
}

// ─── গ্রুপের নাম বের করার হেলপার ──────────────────────────
String _extractGroupName(List<dynamic> group, int index) {
  if (group.isNotEmpty && group[0] is Map) {
    final name = group[0]['group']?.toString();
    if (name != null && name.isNotEmpty) return name;
  }
  // API-তে group না থাকলে A, B, C... করে দিন
  return 'Group ${String.fromCharCode(65 + index)}';
}

Widget _buildH2H(List<dynamic> h2h) {
  debugPrint('🔍 [_buildH2H] Received raw list length: ${h2h.length}');
  if (h2h.isNotEmpty) {
    debugPrint('🔍 [_buildH2H] First item type: ${h2h[0].runtimeType}');
    if (h2h[0] is Map) {
      debugPrint('🔍 [_buildH2H] First item keys: ${(h2h[0] as Map).keys.join(', ')}');
    }
  }

  final List<FixtureModel> mapped = [];
  for (var item in h2h) {
    try {
      if (item is Map) {
        final model = FixtureModel.fromJson(Map<String, dynamic>.from(item));
        mapped.add(model);
      }
    } catch (e) {
      debugPrint('⚠️ [_buildH2H] Parsing failed for item: $e');
    }
  }

  debugPrint('✅ [_buildH2H] Successfully parsed ${mapped.length} fixtures');
  if (mapped.isNotEmpty) {
    debugPrint('✅ [_buildH2H] First parsed fixture: ${mapped[0].fixtureId} - ${mapped[0].homeTeam['name']} vs ${mapped[0].awayTeam['name']}');
  }

  if (mapped.isEmpty) {
    return _sectionCard(
      title: 'Head to Head',
      child: _buildEmpty('No H2H Data', 'No previous meetings found between these teams'),
    );
  }

  return _sectionCard(
    title: 'Head to Head',
    headerExtra: Text('${mapped.length} matches',
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
    child: Column(
      children: mapped.map<Widget>((f) {
        final home = f.homeTeam;
        final away = f.awayTeam;
        final homeScore = f.score['home'] ?? 0;
        final awayScore = f.score['away'] ?? 0;
        final dateStr = f.date != null
            ? '${f.date!.day.toString().padLeft(2, '0')}/${f.date!.month.toString().padLeft(2, '0')}/${f.date!.year}'
            : '';

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.6)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      f.league['name']?.toString() ?? '',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted2),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildH2HTeamLogo(home),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            home['name']?.toString() ?? 'Home',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight:
                                  (homeScore > awayScore) ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13,
                              color: (homeScore > awayScore)
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border2),
                    ),
                    child: Text(
                      '$homeScore : $awayScore',
                      style: const TextStyle(
                        fontFamily: 'Barlow Condensed',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            away['name']?.toString() ?? 'Away',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight:
                                  (awayScore > homeScore) ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13,
                              color: (awayScore > homeScore)
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildH2HTeamLogo(away),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

  Widget _buildH2HTeamLogo(Map<String, dynamic> team) {
    final logo = team['logo']?.toString() ?? '';
    return Container(
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
          color: AppColors.surface2, borderRadius: BorderRadius.circular(8)),
      child: logo.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(logo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                      child: Text(FixtureModel.teamInitials(team),
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted)))))
          : Center(
              child: Text(FixtureModel.teamInitials(team),
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted))),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────

  Widget _buildEmpty(String title, String subtitle) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          const Icon(Icons.sports_soccer, size: 48, color: AppColors.border),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          if (subtitle.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                    textAlign: TextAlign.center))
        ]));
  }
}