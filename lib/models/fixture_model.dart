import 'package:flutter/foundation.dart';

@immutable
class FixtureModel {
  final String fixtureId;
  final DateTime? date;
  final int? timestamp;
  final Map<String, dynamic> status;
  final Map<String, dynamic> league;
  final Map<String, dynamic> teams;
  final Map<String, dynamic> score;
  final Map<String, dynamic> venue;
  final String? referee;
  final String? season;
  final String? homeTeamId;
  final String? awayTeamId;
  final String? leagueId;

  const FixtureModel({
    required this.fixtureId,
    this.date,
    this.timestamp,
    required this.status,
    required this.league,
    required this.teams,
    required this.score,
    required this.venue,
    this.referee,
    this.season,
    this.homeTeamId,
    this.awayTeamId,
    this.leagueId,
  });

  // ─── Helpers ───

  static int? _tryInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // ─── fromJson ───

factory FixtureModel.fromJson(Map<String, dynamic> json) {
  // ─── কোথায় ডেটা আছে? ──────────────────────────────────────
  // কেস ১: API রেসপন্সে "fixture" কী আছে (যেমন H2H-এর প্রতিটি আইটেম)
  // কেস ২: সরাসরি ফিক্সচার ডেটা (যেমন /fixture/<id>/ রেসপন্স)
  // কেস ৩: টপ-লেভেল ফিল্ড (যেমন /fixtures/?date= রেসপন্স)
  
  final d = json['data'] ?? json;
  final f = d['fixture'] ?? d; // যদি fixture অবজেক্ট থাকে, তাহলে সেটা নাও, নাহলে d-ই নাও

  // ─── তারিখ ──────────────────────────────────────────────────
  DateTime? parsedDate;
  if (f['date'] != null) {
    parsedDate = DateTime.tryParse(f['date'].toString());
  }
  parsedDate ??= (json['kickoff'] != null ? DateTime.tryParse(json['kickoff'].toString()) : null);
  parsedDate ??= (json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null);

  // ─── টাইমস্ট্যাম্প ──────────────────────────────────────────
  final timestamp = _tryInt(f['timestamp'] ?? json['timestamp']);

  // ─── স্ট্যাটাস ──────────────────────────────────────────────
  final statusShort = f['status']?['short'] ?? json['status_short'] ?? d['status']?['short'] ?? '';
  final statusLong = f['status']?['long'] ?? json['status_long'] ?? d['status']?['long'] ?? '';
  final elapsed = f['status']?['elapsed'] ?? json['elapsed'] ?? d['status']?['elapsed'] ?? 0;
  final extra = f['status']?['extra'] ?? json['extra'] ?? d['status']?['extra'];
  final isLiveFromApi = json['is_live'] == true;

  // ─── স্কোর ──────────────────────────────────────────────────
  final scoreData = d['score'] ?? json['score'] ?? {};
  final fulltimeHome = scoreData['fulltime']?['home'];
  final fulltimeAway = scoreData['fulltime']?['away'];
  final bool hasFulltimeScore = fulltimeHome != null && fulltimeAway != null;

  // ─── ম্যাচ স্টেট ─────────────────────────────────────────────
  const finishedStatuses = {'FT', 'AET', 'PEN', 'WO', 'AWD', 'CANC', 'ABD'};
  const notStartedStatuses = {'NS', 'TBD'};

  final bool isFinishedByStatus = finishedStatuses.contains(statusShort);
  final bool isNotStartedByStatus = notStartedStatuses.contains(statusShort);

  final bool isFinished = isFinishedByStatus || hasFulltimeScore;
  final bool isNotStarted = isNotStartedByStatus && !isFinished;
  final bool isLive = isLiveFromApi && !isFinished;

  final String displayStatusShort;
  final String displayStatusLong;

  if (isFinished && !isFinishedByStatus) {
    displayStatusShort = 'FT';
    displayStatusLong = 'Match Finished';
  } else {
    displayStatusShort = statusShort;
    displayStatusLong = statusLong;
  }

  final int displayHomeScore;
  final int displayAwayScore;

  if (isFinished && hasFulltimeScore) {
    displayHomeScore = _parseInt(fulltimeHome);
    displayAwayScore = _parseInt(fulltimeAway);
  } else {
    final goalsHome = d['goals']?['home'] ?? scoreData['fulltime']?['home'] ?? json['score']?['home'] ?? 0;
    final goalsAway = d['goals']?['away'] ?? scoreData['fulltime']?['away'] ?? json['score']?['away'] ?? 0;
    displayHomeScore = _parseInt(goalsHome);
    displayAwayScore = _parseInt(goalsAway);
  }

  // ─── টিমের আইডি (H2H-এর জন্য গুরুত্বপূর্ণ) ──────────────────
  // H2H-তে teams অবজেক্ট টপ-লেভেলে থাকে (d['teams']), আবার কোথাও f['teams'] থাকতে পারে
  final teamsData = d['teams'] ?? f['teams'] ?? {};
  final homeTeamId = (teamsData['home']?['id'] ?? json['home_team_id'] ?? '').toString();
  final awayTeamId = (teamsData['away']?['id'] ?? json['away_team_id'] ?? '').toString();

  // ─── লিগের আইডি ──────────────────────────────────────────────
  final leagueData = d['league'] ?? f['league'] ?? json['league'] ?? {};
  final leagueId = (leagueData['id'] ?? json['league_id'] ?? '').toString();
  final season = (leagueData['season'] ?? json['season'] ?? '').toString();

  return FixtureModel(
    fixtureId: (f['id'] ?? json['fixture_id'] ?? json['id'] ?? 0).toString(),
    date: parsedDate,
    timestamp: timestamp,
    status: {
      'long': displayStatusLong,
      'short': displayStatusShort,
      'elapsed': elapsed,
      'extra': extra,
      'is_live': isLive,
      'is_not_started': isNotStarted,
      'is_finished': isFinished,
    },
    league: leagueData,
    teams: teamsData,
    score: {
      'home': displayHomeScore,
      'away': displayAwayScore,
      'halftime': scoreData['halftime'] ?? json['score']?['halftime'],
      'fulltime': scoreData['fulltime'] ?? json['score']?['fulltime'],
      'extratime': scoreData['extratime'] ?? json['score']?['extratime'],
      'penalty': scoreData['penalty'] ?? json['score']?['penalty'],
    },
    venue: f['venue'] ?? json['venue'] ?? {},
    referee: f['referee'] ?? json['referee'],
    season: season,
    homeTeamId: homeTeamId,
    awayTeamId: awayTeamId,
    leagueId: leagueId,
  );
}

  // ─── Getters ───

  bool get isLive => status['is_live'] == true;
  bool get isNS => status['is_not_started'] == true;
  bool get isFinished => status['is_finished'] == true;

  /// Timezone-safe fallback: if status is "NS" but kickoff was 3+
  /// hours ago (in UTC), the match is almost certainly finished.
  /// Handles /fixtures/?date= responses without fulltime score data.
  bool get isProbablyFinished {
    if (isFinished) return true;
    if (isLive) return false;
    if (date == null) return false;
    if (!isNS) return false;
    return DateTime.now().toUtc().difference(date!.toUtc()).inHours >= 3;
  }

  String get round => league['round']?.toString() ?? '';

  Map<String, dynamic> get homeTeam =>
      (teams['home'] is Map<String, dynamic>)
          ? teams['home'] as Map<String, dynamic>
          : <String, dynamic>{};

  Map<String, dynamic> get awayTeam =>
      (teams['away'] is Map<String, dynamic>)
          ? teams['away'] as Map<String, dynamic>
          : <String, dynamic>{};

  static String teamInitials(Map<String, dynamic> team) {
    final name = team['name']?.toString() ?? '?';
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }

  /// Kickoff time in user's LOCAL timezone.
  String get kickoffTime {
    if (date == null) return '--:--';
    final local = date!.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}