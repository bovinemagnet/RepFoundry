import 'package:drift/drift.dart';
import 'cardio_sessions_table.dart';

/// Heart-rate readings recorded during a cardio session, for review and
/// export.
@TableIndex(
  name: 'idx_cardio_heart_rate_samples_session',
  columns: {#sessionId},
)
class CardioHeartRateSamples extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(CardioSessions, #id)();
  IntColumn get timestamp => integer()();
  IntColumn get bpm => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
