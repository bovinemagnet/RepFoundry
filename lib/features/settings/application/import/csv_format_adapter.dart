import '../../../../core/units/weight_unit.dart';
import 'hevy_csv_adapter.dart';
import 'parsed_history.dart';
import 'repfoundry_csv_adapter.dart';
import 'strong_csv_adapter.dart';

/// One CSV dialect (Strong, Hevy, RepFoundry's own export).
abstract class CsvFormatAdapter {
  /// Human-readable name shown in the confirmation dialog.
  String get formatName;

  /// Whether [header] looks like this adapter's format.
  bool matches(List<dynamic> header);

  /// Whether the file's weight unit is undeclared, requiring the user to
  /// choose one before parsing.
  bool requiresUnitChoice(List<dynamic> header) => false;

  /// Parses pre-split CSV rows (header included) into neutral history.
  /// [fallbackUnit] applies only where the file declares no unit.
  ParsedHistory parse(
    List<List<dynamic>> rows, {
    WeightUnit fallbackUnit = WeightUnit.kg,
  });
}

/// Returns the adapter whose header signature matches [rows], or null when
/// no known format matches.
CsvFormatAdapter? detectCsvAdapter(List<List<dynamic>> rows) {
  if (rows.isEmpty) return null;
  final header = rows.first;
  for (final adapter in <CsvFormatAdapter>[
    HevyCsvAdapter(),
    StrongCsvAdapter(),
    RepFoundryCsvAdapter(),
  ]) {
    if (adapter.matches(header)) return adapter;
  }
  return null;
}

/// Shared row helpers for the concrete adapters.
mixin CsvRowParsing {
  /// Case-insensitive column index lookup; -1 when absent.
  Map<String, int> headerIndex(List<dynamic> header) {
    return {
      for (var i = 0; i < header.length; i++)
        header[i].toString().trim().toLowerCase(): i,
    };
  }

  String cell(List<dynamic> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index].toString().trim();
  }

  double? parseDouble(String value) => double.tryParse(value);

  int? parseInt(String value) => int.tryParse(value);
}
