import 'package:hr_zones/hr_zones.dart';

import '../../../cardio/application/build_cardio_history_use_case.dart';
import '../../../cardio/application/cardio_history_entry.dart';
import '../../../cardio/application/cardio_progress.dart';
import '../../../clients/domain/repositories/health_profile_repository.dart';
import '../../../heart_rate/application/build_weekly_heart_report_use_case.dart';
import '../mcp_args.dart';
import '../mcp_scope.dart';
import '../mcp_tool.dart';

const Map<String, Object?> _sportSchema = {
  'type': 'string',
  'description': 'Cardio exercise name, e.g. "Outdoor Run" (case-insensitive).',
};

/// Cardio history entries for [clientId], optionally one sport only.
Future<List<CardioHistoryEntry>> _entries(
  BuildCardioHistoryUseCase history,
  String clientId,
  String? sport,
) async {
  final all = await history.execute(clientId: clientId);
  return [
    for (final e in all)
      if (!e.session.isDeleted &&
          (sport == null ||
              e.exerciseName.toLowerCase() == sport.toLowerCase()))
        e,
  ];
}

/// Cardio sessions, newest first. Summaries only, never the route.
class ListCardioSessionsTool implements McpTool {
  ListCardioSessionsTool(this._history, this._scope);

  final BuildCardioHistoryUseCase _history;
  final McpScope _scope;

  @override
  String get name => 'list_cardio_sessions';

  @override
  String get description =>
      'Lists cardio sessions newest first with sport, duration, distance, '
      'pace and average heart rate. Routes and GPS positions are never '
      'included. Page with `next_cursor`.';

  @override
  Map<String, Object?> get inputSchema => objectSchema({
        'sport': _sportSchema,
        'from': kFromSchema,
        'to': kToSchema,
        'limit': kLimitSchema,
        'cursor': kCursorSchema,
        'client_id': kClientIdSchema,
      });

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final clientId = await _scope.resolveClientId(args);
    final sport = optionalString(args, 'sport');
    final limit = parseLimit(args);
    final from = parseDate(args, 'from');
    final to = parseDate(args, 'to');
    final before = decodeCursor(args) ?? to;

    final matching = (await _entries(_history, clientId, sport))
        .where((e) =>
            (from == null || !e.startedAt.isBefore(from)) &&
            (before == null || e.startedAt.isBefore(before)))
        .toList();
    final page = matching.take(limit).toList();

    return {
      'sessions': [
        for (final e in page)
          {
            'id': e.session.id,
            'workout_id': e.session.workoutId,
            'sport': e.exerciseName,
            'started_at': isoLocal(e.startedAt),
            'duration_seconds': e.session.durationSeconds,
            'distance_km': round2OrNull(e.distanceKm),
            'pace_min_per_km': round2OrNull(e.paceMinutesPerKm),
            'incline': e.session.incline,
            'avg_hr_bpm': e.session.avgHeartRate,
          },
      ],
      'next_cursor':
          matching.length > limit ? encodeCursor(page.last.startedAt) : null,
    };
  }
}

/// Six-week cardio totals, as on the cardio Progress view.
class GetCardioProgressTool implements McpTool {
  GetCardioProgressTool(this._history, this._scope, this._now);

  final BuildCardioHistoryUseCase _history;
  final McpScope _scope;
  final DateTime Function() _now;

  static const int weeks = 6;

  @override
  String get name => 'get_cardio_progress';

  @override
  String get description =>
      'Summarises the last six local weeks of cardio: total distance, '
      'sessions and time, distance per week (oldest first), best pace, '
      'average heart rate and the pace trend.';

  @override
  Map<String, Object?> get inputSchema => objectSchema({
        'sport': _sportSchema,
        'client_id': kClientIdSchema,
      });

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final clientId = await _scope.resolveClientId(args);
    final sport = optionalString(args, 'sport');
    final p = CardioProgress.compute(
      await _entries(_history, clientId, sport),
      now: _now(),
      weeks: weeks,
    );
    return {
      'weeks': weeks,
      'total_distance_km': round2(p.totalDistanceKm),
      'session_count': p.sessionCount,
      'total_duration_seconds': p.totalDuration.inSeconds,
      'weekly_distance_km': [for (final km in p.weeklyDistanceKm) round2(km)],
      'best_pace_min_per_km': round2OrNull(p.bestPaceMinutesPerKm),
      'avg_hr_bpm': p.avgHeartRate,
      'pace_trend': [
        for (final point in p.paceTrend)
          {
            'date': isoLocal(point.date),
            'pace_min_per_km': round2(point.minutesPerKm),
          },
      ],
    };
  }
}

/// The last seven days of heart-rate activity.
class GetWeeklyHeartReportTool implements McpTool {
  GetWeeklyHeartReportTool(
    this._report,
    this._profiles,
    this._scope,
    this._now,
  );

  final BuildWeeklyHeartReportUseCase _report;
  final HealthProfileRepository _profiles;
  final McpScope _scope;
  final DateTime Function() _now;

  @override
  String get name => 'get_weekly_heart_report';

  @override
  String get description =>
      'Reports the last seven days of heart rate: each session with its '
      'average and peak, the overall average and peak, the highest reading '
      'per day (oldest first) and seconds of cardio spent in each training '
      'zone (empty when zones cannot be worked out).';

  @override
  Map<String, Object?> get inputSchema =>
      objectSchema({'client_id': kClientIdSchema});

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final clientId = await _scope.resolveClientId(args);
    final zones = calculateZones(await _profiles.getForClient(clientId));
    final r =
        await _report.execute(clientId: clientId, now: _now(), zones: zones);
    return {
      'sessions': [
        for (final s in r.sessions)
          {
            'workout_id': s.workoutId,
            'kind': s.kind.name,
            'title': s.title,
            'started_at': isoLocal(s.startedAt),
            'avg_bpm': s.avgBpm,
            'peak_bpm': s.peakBpm,
          },
      ],
      'avg_bpm': r.avgBpm,
      'peak_bpm': r.peakBpm,
      'daily_peak_bpm': r.dailyPeakBpm,
      'seconds_in_zone': {
        for (final e in r.secondsInZone.entries) '${e.key}': e.value,
      },
    };
  }
}
