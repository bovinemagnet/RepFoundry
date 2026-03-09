import 'package:drift/drift.dart';

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get category => text()();
  TextColumn get muscleGroup => text()();
  TextColumn get equipmentType => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get imageAsset => text().nullable()();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
