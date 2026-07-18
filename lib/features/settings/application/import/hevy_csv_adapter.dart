import 'package:intl/intl.dart';

import '../../../../core/units/weight_unit.dart';
import 'csv_format_adapter.dart';
import 'parsed_history.dart';

/// Parses the Hevy app's CSV export. Weights are always kilograms
/// (`weight_kg` column); warm-ups arrive as `set_type: warmup`.
class HevyCsvAdapter extends CsvFormatAdapter with CsvRowParsing {
  @override
  String get formatName => 'Hevy';

  @override
  bool matches(List<dynamic> header) {
    final index = headerIndex(header);
    return index.containsKey('exercise_title') &&
        index.containsKey('weight_kg');
  }

  @override
  ParsedHistory parse(
    List<List<dynamic>> rows, {
    WeightUnit fallbackUnit = WeightUnit.kg,
  }) {
    final index = headerIndex(rows.first);

    var skipped = 0;
    final groups = <String, List<List<dynamic>>>{};
    for (final row in rows.skip(1)) {
      if (row.every((c) => c.toString().trim().isEmpty)) continue;
      final key =
          '${cell(row, index['start_time'])}|${cell(row, index['title'])}';
      groups.putIfAbsent(key, () => []).add(row);
    }

    final workouts = <ParsedWorkout>[];
    for (final entry in groups.entries) {
      final firstRow = entry.value.first;
      final startedAt = _parseHevyDate(cell(firstRow, index['start_time']));
      if (startedAt == null) {
        skipped += entry.value.length;
        continue;
      }
      final endedAt = _parseHevyDate(cell(firstRow, index['end_time']));
      final name = cell(firstRow, index['title']);

      final sets = <ParsedSet>[];
      for (final row in entry.value) {
        final reps = parseInt(cell(row, index['reps'])) ?? 0;
        if (reps <= 0) {
          skipped++;
          continue;
        }
        sets.add(ParsedSet(
          exerciseName: cell(row, index['exercise_title']),
          weightKg: parseDouble(cell(row, index['weight_kg'])) ?? 0,
          reps: reps,
          rpe: parseDouble(cell(row, index['rpe'])),
          isWarmUp: cell(row, index['set_type']).toLowerCase() == 'warmup',
          timestamp: startedAt.add(Duration(minutes: sets.length)),
        ));
      }
      if (sets.isEmpty) continue;

      workouts.add(ParsedWorkout(
        sourceKey: entry.key,
        name: name.isEmpty ? null : name,
        startedAt: startedAt,
        completedAt: endedAt ?? startedAt.add(const Duration(hours: 1)),
        sets: sets,
      ));
    }

    return ParsedHistory(
      source: 'hevy',
      workouts: workouts,
      rowsSkipped: skipped,
    );
  }

  /// Hevy has used both ISO-8601 and "15 Mar 2024, 09:10" styles.
  DateTime? _parseHevyDate(String text) {
    if (text.isEmpty) return null;
    final iso = DateTime.tryParse(text);
    if (iso != null) return iso.toUtc();
    try {
      return DateFormat('d MMM yyyy, HH:mm').parse(text).toUtc();
    } on FormatException {
      return null;
    }
  }
}
