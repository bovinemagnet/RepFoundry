/// Converts between [DateTime] (UTC) and epoch milliseconds stored as [int].
DateTime dateTimeFromEpochMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

int dateTimeToEpochMs(DateTime dt) => dt.toUtc().millisecondsSinceEpoch;

DateTime? nullableDateTimeFromEpochMs(int? ms) =>
    ms == null ? null : dateTimeFromEpochMs(ms);

int? nullableDateTimeToEpochMs(DateTime? dt) =>
    dt == null ? null : dateTimeToEpochMs(dt);

/// Converts an enum value to its [String] name and back.
T enumFromString<T extends Enum>(List<T> values, String name) =>
    values.firstWhere((v) => v.name == name);
