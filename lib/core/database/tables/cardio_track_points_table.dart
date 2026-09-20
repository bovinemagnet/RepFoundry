import 'package:drift/drift.dart';
import 'cardio_sessions_table.dart';

/// GPS fixes recorded during a cardio session, for review and export.
@TableIndex(name: 'idx_cardio_track_points_session', columns: {#sessionId})
class CardioTrackPoints extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(CardioSessions, #id)();
  IntColumn get timestamp => integer()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get altitude => real().nullable()();
  RealColumn get accuracy => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
