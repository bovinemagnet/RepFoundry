import 'package:intl/intl.dart';

import '../../../../core/units/weight_unit.dart';
import 'csv_format_adapter.dart';
import 'parsed_history.dart';

/// Round-trips RepFoundry's own `sets.csv` export
/// (`date,exercise,weight,reps,rpe,volume,e1rm`).
///
/// The export carries no workout boundaries, so sets are grouped into one
/// workout per calendar day, starting at the day's first set and completing
/// at its last. Weights are kg by definition.
class RepFoundryCsvAdapter extends CsvFormatAdapter with CsvRowParsing {
  @override
  String get formatName => 'RepFoundry CSV';

  @override
  bool matches(List<dynamic> header) {
    final index = headerIndex(header);
    return index.containsKey('date') &&
        index.containsKey('exercise') &&
        index.containsKey('e1rm');
  }

  @override
  ParsedHistory parse(
    List<List<dynamic>> rows, {
    WeightUnit fallbackUnit = WeightUnit.kg,
  }) {
    final index = headerIndex(rows.first);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    var skipped = 0;
    final byDay = <String, List<ParsedSet>>{};
    for (final row in rows.skip(1)) {
      if (row.every((c) => c.toString().trim().isEmpty)) continue;
      final DateTime timestamp;
      try {
        timestamp = dateFormat.parse(cell(row, index['date'])).toUtc();
      } on FormatException {
        skipped++;
        continue;
      }
      final reps = parseInt(cell(row, index['reps'])) ?? 0;
      if (reps <= 0) {
        skipped++;
        continue;
      }
      final day = cell(row, index['date']).split(' ').first;
      byDay.putIfAbsent(day, () => []).add(ParsedSet(
            exerciseName: cell(row, index['exercise']),
            weightKg: parseDouble(cell(row, index['weight'])) ?? 0,
            reps: reps,
            rpe: parseDouble(cell(row, index['rpe'])),
            timestamp: timestamp,
          ));
    }

    final workouts = <ParsedWorkout>[];
    for (final entry in byDay.entries) {
      final sets = entry.value;
      workouts.add(ParsedWorkout(
        sourceKey: entry.key,
        startedAt: sets.first.timestamp,
        completedAt: sets.last.timestamp.add(const Duration(minutes: 5)),
        sets: sets,
      ));
    }

    return ParsedHistory(
      source: 'repfoundry',
      workouts: workouts,
      rowsSkipped: skipped,
    );
  }
}
