import 'package:intl/intl.dart';

import '../../../../core/units/weight_unit.dart';
import 'csv_format_adapter.dart';
import 'parsed_history.dart';

/// Parses the Strong app's CSV export.
///
/// Two header variants exist in the wild: the compact layout
/// (`Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,...`)
/// whose weight unit depends on the exporting user's app setting, and an
/// older layout carrying explicit `Weight Unit` / `Distance Unit` columns.
class StrongCsvAdapter extends CsvFormatAdapter with CsvRowParsing {
  @override
  String get formatName => 'Strong';

  @override
  bool matches(List<dynamic> header) {
    final index = headerIndex(header);
    return index.containsKey('exercise name') && index.containsKey('set order');
  }

  @override
  bool requiresUnitChoice(List<dynamic> header) {
    return !headerIndex(header).containsKey('weight unit');
  }

  @override
  ParsedHistory parse(
    List<List<dynamic>> rows, {
    WeightUnit fallbackUnit = WeightUnit.kg,
  }) {
    final index = headerIndex(rows.first);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    var skipped = 0;
    // Keyed by (date string, workout name) preserving file order.
    final groups = <String, List<List<dynamic>>>{};
    for (final row in rows.skip(1)) {
      if (row.every((c) => c.toString().trim().isEmpty)) continue;
      final key =
          '${cell(row, index['date'])}|${cell(row, index['workout name'])}';
      groups.putIfAbsent(key, () => []).add(row);
    }

    final workouts = <ParsedWorkout>[];
    for (final entry in groups.entries) {
      final firstRow = entry.value.first;
      final DateTime startedAt;
      try {
        startedAt = dateFormat.parse(cell(firstRow, index['date'])).toUtc();
      } on FormatException {
        skipped += entry.value.length;
        continue;
      }
      final name = cell(firstRow, index['workout name']);
      final duration = _parseDuration(cell(firstRow, index['duration'])) ??
          const Duration(hours: 1);

      final sets = <ParsedSet>[];
      for (final row in entry.value) {
        final weightText = cell(row, index['weight']);
        final reps = parseInt(cell(row, index['reps'])) ?? 0;
        final distance = cell(row, index['distance']);
        final seconds = cell(row, index['seconds']);
        final isCardioShaped =
            reps <= 0 && (distance.isNotEmpty || seconds.isNotEmpty);
        if (isCardioShaped || reps <= 0) {
          skipped++;
          continue;
        }

        final rowUnit = _rowUnit(cell(row, index['weight unit']), fallbackUnit);
        final weight = parseDouble(weightText) ?? 0;

        final setOrderText = cell(row, index['set order']);
        final isWarmUp = setOrderText.toUpperCase().startsWith('W');

        sets.add(ParsedSet(
          exerciseName: cell(row, index['exercise name']),
          weightKg: rowUnit.toKg(weight),
          reps: reps,
          rpe: parseDouble(cell(row, index['rpe'])),
          isWarmUp: isWarmUp,
          timestamp: startedAt.add(Duration(minutes: sets.length)),
        ));
      }
      if (sets.isEmpty) continue;

      workouts.add(ParsedWorkout(
        sourceKey: entry.key,
        name: name.isEmpty ? null : name,
        startedAt: startedAt,
        completedAt: startedAt.add(duration),
        sets: sets,
      ));
    }

    return ParsedHistory(
      source: 'strong',
      workouts: workouts,
      rowsSkipped: skipped,
    );
  }

  WeightUnit _rowUnit(String declared, WeightUnit fallback) {
    switch (declared.toLowerCase()) {
      case 'kg':
        return WeightUnit.kg;
      case 'lb':
      case 'lbs':
        return WeightUnit.lbs;
      default:
        return fallback;
    }
  }

  /// Strong durations look like "1h 5m", "45m", or "2h".
  Duration? _parseDuration(String text) {
    if (text.isEmpty) return null;
    final hours = RegExp(r'(\d+)\s*h').firstMatch(text)?.group(1);
    final minutes = RegExp(r'(\d+)\s*m').firstMatch(text)?.group(1);
    if (hours == null && minutes == null) return null;
    return Duration(
      hours: int.tryParse(hours ?? '') ?? 0,
      minutes: int.tryParse(minutes ?? '') ?? 0,
    );
  }
}
