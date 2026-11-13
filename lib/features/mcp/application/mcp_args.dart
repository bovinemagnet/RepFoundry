import 'dart:convert';

import 'mcp_tool.dart';

/// Default and maximum page size for list tools.
const int kDefaultMcpLimit = 20;
const int kMaxMcpLimit = 100;

/// Reads `limit`, clamped to 1..[max]. A non-integer is a tool error.
int parseLimit(
  Map<String, Object?> args, {
  int defaultValue = kDefaultMcpLimit,
  int max = kMaxMcpLimit,
  String key = 'limit',
}) {
  final raw = args[key];
  if (raw == null) return defaultValue;
  if (raw is! num || raw != raw.roundToDouble()) {
    throw McpToolError('$key must be a whole number');
  }
  return raw.toInt().clamp(1, max);
}

/// Reads an ISO 8601 date or date-time. A date alone is local midnight.
DateTime? parseDate(Map<String, Object?> args, String key) {
  final raw = args[key];
  if (raw == null) return null;
  final parsed = raw is String ? DateTime.tryParse(raw) : null;
  if (parsed == null) {
    throw McpToolError('$key must be an ISO 8601 date, e.g. 2026-11-01');
  }
  return parsed;
}

/// Reads a required, non-empty string argument.
String requireString(Map<String, Object?> args, String key) {
  final raw = args[key];
  if (raw is! String || raw.isEmpty) {
    throw McpToolError('$key is required');
  }
  return raw;
}

/// Reads an optional string argument.
String? optionalString(Map<String, Object?> args, String key) {
  final raw = args[key];
  if (raw == null) return null;
  if (raw is! String) throw McpToolError('$key must be a string');
  return raw;
}

/// An opaque paging cursor: the instant the next page must start before.
String encodeCursor(DateTime before) => base64Url
    .encode(utf8.encode(before.millisecondsSinceEpoch.toString()))
    .replaceAll('=', '');

/// Reads `cursor`, or null when absent. A forged value is a tool error.
DateTime? decodeCursor(Map<String, Object?> args) {
  final raw = args['cursor'];
  if (raw == null) return null;
  try {
    final text =
        utf8.decode(base64Url.decode(base64Url.normalize(raw as String)));
    return DateTime.fromMillisecondsSinceEpoch(int.parse(text), isUtc: true);
  } catch (_) {
    throw const McpToolError('Invalid cursor');
  }
}

/// ISO 8601 in local time with an explicit offset, e.g. `+11:00`.
String isoLocal(DateTime value) {
  final local = value.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final minutes = offset.inMinutes.abs();
  final hh = (minutes ~/ 60).toString().padLeft(2, '0');
  final mm = (minutes % 60).toString().padLeft(2, '0');
  final base = local.toIso8601String();
  // A local DateTime's ISO string has no zone suffix; drop sub-millisecond
  // digits so the result stays within millisecond precision.
  final trimmed = base.length > 23 ? base.substring(0, 23) : base;
  return '$trimmed$sign$hh:$mm';
}

/// [isoLocal] when present.
String? isoLocalOrNull(DateTime? value) =>
    value == null ? null : isoLocal(value);

/// A local calendar date, `yyyy-MM-dd`.
String isoDate(DateTime value) {
  final d = value.toLocal();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Rounds to two decimal places for weights, distances and paces.
double round2(double value) => (value * 100).roundToDouble() / 100;

/// Rounds when present.
double? round2OrNull(double? value) => value == null ? null : round2(value);

/// A JSON Schema object with [properties].
Map<String, Object?> objectSchema(
  Map<String, Object?> properties, {
  List<String> required = const [],
}) =>
    {
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
    };

/// Schema fragments shared by several tools.
const Map<String, Object?> kLimitSchema = {
  'type': 'integer',
  'minimum': 1,
  'maximum': kMaxMcpLimit,
  'description': 'Page size, default 20, at most 100.',
};
const Map<String, Object?> kCursorSchema = {
  'type': 'string',
  'description': 'next_cursor from the previous page.',
};
const Map<String, Object?> kFromSchema = {
  'type': 'string',
  'description': 'Earliest date to include, ISO 8601 (e.g. 2026-11-01).',
};
const Map<String, Object?> kToSchema = {
  'type': 'string',
  'description': 'Include only items before this date-time, ISO 8601.',
};
const Map<String, Object?> kClientIdSchema = {
  'type': 'string',
  'description': "Client to read; omit for your own data. Only accepted when "
      'client data access is on.',
};
