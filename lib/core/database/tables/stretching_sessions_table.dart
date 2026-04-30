import 'package:drift/drift.dart';
import 'workouts_table.dart';

@TableIndex(
  name: 'idx_stretching_sessions_workout',
  columns: {#workoutId},
)
@TableIndex(
  name: 'idx_stretching_sessions_type_updated',
  columns: {#type, #updatedAt},
)
class StretchingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text().references(Workouts, #id)();

  /// Either a preset key or 'custom'.
  TextColumn get type => text()();

  TextColumn get customName => text().nullable()();

  /// Enum name for [StretchingBodyArea]; nullable.
  TextColumn get bodyArea => text().nullable()();

  /// Enum name for [StretchingSide]; nullable.
  TextColumn get side => text().nullable()();

  IntColumn get durationSeconds => integer()();

  /// Wall-clock start, epoch ms; null for manual entries.
  IntColumn get startedAt => integer().nullable()();

  /// Wall-clock end, epoch ms; null for manual entries.
  IntColumn get endedAt => integer().nullable()();

  /// Enum name for [StretchingEntryMethod].
  TextColumn get entryMethod => text()();

  TextColumn get notes => text().nullable()();

  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
