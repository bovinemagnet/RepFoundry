// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BodyMetricsTable extends BodyMetrics
    with TableInfo<$BodyMetricsTable, BodyMetric> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyMetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
      'date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _bodyFatPercentMeta =
      const VerificationMeta('bodyFatPercent');
  @override
  late final GeneratedColumn<double> bodyFatPercent = GeneratedColumn<double>(
      'body_fat_percent', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, weight, bodyFatPercent, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_metrics';
  @override
  VerificationContext validateIntegrity(Insertable<BodyMetric> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('body_fat_percent')) {
      context.handle(
          _bodyFatPercentMeta,
          bodyFatPercent.isAcceptableOrUnknown(
              data['body_fat_percent']!, _bodyFatPercentMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyMetric map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyMetric(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      bodyFatPercent: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}body_fat_percent']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $BodyMetricsTable createAlias(String alias) {
    return $BodyMetricsTable(attachedDatabase, alias);
  }
}

class BodyMetric extends DataClass implements Insertable<BodyMetric> {
  final String id;
  final int date;
  final double weight;
  final double? bodyFatPercent;
  final String? notes;
  const BodyMetric(
      {required this.id,
      required this.date,
      required this.weight,
      this.bodyFatPercent,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<int>(date);
    map['weight'] = Variable<double>(weight);
    if (!nullToAbsent || bodyFatPercent != null) {
      map['body_fat_percent'] = Variable<double>(bodyFatPercent);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  BodyMetricsCompanion toCompanion(bool nullToAbsent) {
    return BodyMetricsCompanion(
      id: Value(id),
      date: Value(date),
      weight: Value(weight),
      bodyFatPercent: bodyFatPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPercent),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory BodyMetric.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyMetric(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<int>(json['date']),
      weight: serializer.fromJson<double>(json['weight']),
      bodyFatPercent: serializer.fromJson<double?>(json['bodyFatPercent']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<int>(date),
      'weight': serializer.toJson<double>(weight),
      'bodyFatPercent': serializer.toJson<double?>(bodyFatPercent),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  BodyMetric copyWith(
          {String? id,
          int? date,
          double? weight,
          Value<double?> bodyFatPercent = const Value.absent(),
          Value<String?> notes = const Value.absent()}) =>
      BodyMetric(
        id: id ?? this.id,
        date: date ?? this.date,
        weight: weight ?? this.weight,
        bodyFatPercent:
            bodyFatPercent.present ? bodyFatPercent.value : this.bodyFatPercent,
        notes: notes.present ? notes.value : this.notes,
      );
  BodyMetric copyWithCompanion(BodyMetricsCompanion data) {
    return BodyMetric(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      weight: data.weight.present ? data.weight.value : this.weight,
      bodyFatPercent: data.bodyFatPercent.present
          ? data.bodyFatPercent.value
          : this.bodyFatPercent,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyMetric(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('weight: $weight, ')
          ..write('bodyFatPercent: $bodyFatPercent, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, weight, bodyFatPercent, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyMetric &&
          other.id == this.id &&
          other.date == this.date &&
          other.weight == this.weight &&
          other.bodyFatPercent == this.bodyFatPercent &&
          other.notes == this.notes);
}

class BodyMetricsCompanion extends UpdateCompanion<BodyMetric> {
  final Value<String> id;
  final Value<int> date;
  final Value<double> weight;
  final Value<double?> bodyFatPercent;
  final Value<String?> notes;
  final Value<int> rowid;
  const BodyMetricsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.weight = const Value.absent(),
    this.bodyFatPercent = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BodyMetricsCompanion.insert({
    required String id,
    required int date,
    required double weight,
    this.bodyFatPercent = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        date = Value(date),
        weight = Value(weight);
  static Insertable<BodyMetric> custom({
    Expression<String>? id,
    Expression<int>? date,
    Expression<double>? weight,
    Expression<double>? bodyFatPercent,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (weight != null) 'weight': weight,
      if (bodyFatPercent != null) 'body_fat_percent': bodyFatPercent,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BodyMetricsCompanion copyWith(
      {Value<String>? id,
      Value<int>? date,
      Value<double>? weight,
      Value<double?>? bodyFatPercent,
      Value<String?>? notes,
      Value<int>? rowid}) {
    return BodyMetricsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (bodyFatPercent.present) {
      map['body_fat_percent'] = Variable<double>(bodyFatPercent.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyMetricsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('weight: $weight, ')
          ..write('bodyFatPercent: $bodyFatPercent, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _muscleGroupMeta =
      const VerificationMeta('muscleGroup');
  @override
  late final GeneratedColumn<String> muscleGroup = GeneratedColumn<String>(
      'muscle_group', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _equipmentTypeMeta =
      const VerificationMeta('equipmentType');
  @override
  late final GeneratedColumn<String> equipmentType = GeneratedColumn<String>(
      'equipment_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCustomMeta =
      const VerificationMeta('isCustom');
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
      'is_custom', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_custom" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _imageAssetMeta =
      const VerificationMeta('imageAsset');
  @override
  late final GeneratedColumn<String> imageAsset = GeneratedColumn<String>(
      'image_asset', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        category,
        muscleGroup,
        equipmentType,
        isCustom,
        imageAsset,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(Insertable<Exercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('muscle_group')) {
      context.handle(
          _muscleGroupMeta,
          muscleGroup.isAcceptableOrUnknown(
              data['muscle_group']!, _muscleGroupMeta));
    } else if (isInserting) {
      context.missing(_muscleGroupMeta);
    }
    if (data.containsKey('equipment_type')) {
      context.handle(
          _equipmentTypeMeta,
          equipmentType.isAcceptableOrUnknown(
              data['equipment_type']!, _equipmentTypeMeta));
    } else if (isInserting) {
      context.missing(_equipmentTypeMeta);
    }
    if (data.containsKey('is_custom')) {
      context.handle(_isCustomMeta,
          isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta));
    }
    if (data.containsKey('image_asset')) {
      context.handle(
          _imageAssetMeta,
          imageAsset.isAcceptableOrUnknown(
              data['image_asset']!, _imageAssetMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      muscleGroup: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}muscle_group'])!,
      equipmentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}equipment_type'])!,
      isCustom: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_custom'])!,
      imageAsset: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_asset']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final String id;
  final String name;
  final String category;
  final String muscleGroup;
  final String equipmentType;
  final bool isCustom;
  final String? imageAsset;
  final int? deletedAt;
  const Exercise(
      {required this.id,
      required this.name,
      required this.category,
      required this.muscleGroup,
      required this.equipmentType,
      required this.isCustom,
      this.imageAsset,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['muscle_group'] = Variable<String>(muscleGroup);
    map['equipment_type'] = Variable<String>(equipmentType);
    map['is_custom'] = Variable<bool>(isCustom);
    if (!nullToAbsent || imageAsset != null) {
      map['image_asset'] = Variable<String>(imageAsset);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      muscleGroup: Value(muscleGroup),
      equipmentType: Value(equipmentType),
      isCustom: Value(isCustom),
      imageAsset: imageAsset == null && nullToAbsent
          ? const Value.absent()
          : Value(imageAsset),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      muscleGroup: serializer.fromJson<String>(json['muscleGroup']),
      equipmentType: serializer.fromJson<String>(json['equipmentType']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      imageAsset: serializer.fromJson<String?>(json['imageAsset']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'muscleGroup': serializer.toJson<String>(muscleGroup),
      'equipmentType': serializer.toJson<String>(equipmentType),
      'isCustom': serializer.toJson<bool>(isCustom),
      'imageAsset': serializer.toJson<String?>(imageAsset),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Exercise copyWith(
          {String? id,
          String? name,
          String? category,
          String? muscleGroup,
          String? equipmentType,
          bool? isCustom,
          Value<String?> imageAsset = const Value.absent(),
          Value<int?> deletedAt = const Value.absent()}) =>
      Exercise(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        muscleGroup: muscleGroup ?? this.muscleGroup,
        equipmentType: equipmentType ?? this.equipmentType,
        isCustom: isCustom ?? this.isCustom,
        imageAsset: imageAsset.present ? imageAsset.value : this.imageAsset,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      muscleGroup:
          data.muscleGroup.present ? data.muscleGroup.value : this.muscleGroup,
      equipmentType: data.equipmentType.present
          ? data.equipmentType.value
          : this.equipmentType,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      imageAsset:
          data.imageAsset.present ? data.imageAsset.value : this.imageAsset,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('equipmentType: $equipmentType, ')
          ..write('isCustom: $isCustom, ')
          ..write('imageAsset: $imageAsset, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, category, muscleGroup,
      equipmentType, isCustom, imageAsset, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.muscleGroup == this.muscleGroup &&
          other.equipmentType == this.equipmentType &&
          other.isCustom == this.isCustom &&
          other.imageAsset == this.imageAsset &&
          other.deletedAt == this.deletedAt);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<String> muscleGroup;
  final Value<String> equipmentType;
  final Value<bool> isCustom;
  final Value<String?> imageAsset;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.muscleGroup = const Value.absent(),
    this.equipmentType = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.imageAsset = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String name,
    required String category,
    required String muscleGroup,
    required String equipmentType,
    this.isCustom = const Value.absent(),
    this.imageAsset = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        category = Value(category),
        muscleGroup = Value(muscleGroup),
        equipmentType = Value(equipmentType);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? muscleGroup,
    Expression<String>? equipmentType,
    Expression<bool>? isCustom,
    Expression<String>? imageAsset,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (muscleGroup != null) 'muscle_group': muscleGroup,
      if (equipmentType != null) 'equipment_type': equipmentType,
      if (isCustom != null) 'is_custom': isCustom,
      if (imageAsset != null) 'image_asset': imageAsset,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? category,
      Value<String>? muscleGroup,
      Value<String>? equipmentType,
      Value<bool>? isCustom,
      Value<String?>? imageAsset,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipmentType: equipmentType ?? this.equipmentType,
      isCustom: isCustom ?? this.isCustom,
      imageAsset: imageAsset ?? this.imageAsset,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (muscleGroup.present) {
      map['muscle_group'] = Variable<String>(muscleGroup.value);
    }
    if (equipmentType.present) {
      map['equipment_type'] = Variable<String>(equipmentType.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (imageAsset.present) {
      map['image_asset'] = Variable<String>(imageAsset.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('equipmentType: $equipmentType, ')
          ..write('isCustom: $isCustom, ')
          ..write('imageAsset: $imageAsset, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutsTable extends Workouts with TableInfo<$WorkoutsTable, Workout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
      'started_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _templateIdMeta =
      const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
      'template_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, startedAt, completedAt, templateId, notes, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(Insertable<Workout> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
          _templateIdMeta,
          templateId.isAcceptableOrUnknown(
              data['template_id']!, _templateIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workout(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_at']),
      templateId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }
}

class Workout extends DataClass implements Insertable<Workout> {
  final String id;
  final int startedAt;
  final int? completedAt;
  final String? templateId;
  final String? notes;
  final int? deletedAt;
  const Workout(
      {required this.id,
      required this.startedAt,
      this.completedAt,
      this.templateId,
      this.notes,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Workout.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workout(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      notes: serializer.fromJson<String?>(json['notes']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<int>(startedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
      'templateId': serializer.toJson<String?>(templateId),
      'notes': serializer.toJson<String?>(notes),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Workout copyWith(
          {String? id,
          int? startedAt,
          Value<int?> completedAt = const Value.absent(),
          Value<String?> templateId = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<int?> deletedAt = const Value.absent()}) =>
      Workout(
        id: id ?? this.id,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        templateId: templateId.present ? templateId.value : this.templateId,
        notes: notes.present ? notes.value : this.notes,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Workout copyWithCompanion(WorkoutsCompanion data) {
    return Workout(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      templateId:
          data.templateId.present ? data.templateId.value : this.templateId,
      notes: data.notes.present ? data.notes.value : this.notes,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workout(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('templateId: $templateId, ')
          ..write('notes: $notes, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startedAt, completedAt, templateId, notes, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workout &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.templateId == this.templateId &&
          other.notes == this.notes &&
          other.deletedAt == this.deletedAt);
}

class WorkoutsCompanion extends UpdateCompanion<Workout> {
  final Value<String> id;
  final Value<int> startedAt;
  final Value<int?> completedAt;
  final Value<String?> templateId;
  final Value<String?> notes;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.templateId = const Value.absent(),
    this.notes = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    required String id,
    required int startedAt,
    this.completedAt = const Value.absent(),
    this.templateId = const Value.absent(),
    this.notes = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        startedAt = Value(startedAt);
  static Insertable<Workout> custom({
    Expression<String>? id,
    Expression<int>? startedAt,
    Expression<int>? completedAt,
    Expression<String>? templateId,
    Expression<String>? notes,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (templateId != null) 'template_id': templateId,
      if (notes != null) 'notes': notes,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutsCompanion copyWith(
      {Value<String>? id,
      Value<int>? startedAt,
      Value<int?>? completedAt,
      Value<String?>? templateId,
      Value<String?>? notes,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      templateId: templateId ?? this.templateId,
      notes: notes ?? this.notes,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('templateId: $templateId, ')
          ..write('notes: $notes, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSetsTable extends WorkoutSets
    with TableInfo<$WorkoutSetsTable, WorkoutSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workoutIdMeta =
      const VerificationMeta('workoutId');
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
      'workout_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES workouts (id)'));
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _setOrderMeta =
      const VerificationMeta('setOrder');
  @override
  late final GeneratedColumn<int> setOrder = GeneratedColumn<int>(
      'set_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<double> rpe = GeneratedColumn<double>(
      'rpe', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isWarmUpMeta =
      const VerificationMeta('isWarmUp');
  @override
  late final GeneratedColumn<bool> isWarmUp = GeneratedColumn<bool>(
      'is_warm_up', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_warm_up" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        workoutId,
        exerciseId,
        setOrder,
        weight,
        reps,
        rpe,
        timestamp,
        isWarmUp,
        groupId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sets';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutSet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(_workoutIdMeta,
          workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta));
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('set_order')) {
      context.handle(_setOrderMeta,
          setOrder.isAcceptableOrUnknown(data['set_order']!, _setOrderMeta));
    } else if (isInserting) {
      context.missing(_setOrderMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('rpe')) {
      context.handle(
          _rpeMeta, rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_warm_up')) {
      context.handle(_isWarmUpMeta,
          isWarmUp.isAcceptableOrUnknown(data['is_warm_up']!, _isWarmUpMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workoutId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      setOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}set_order'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      rpe: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rpe']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      isWarmUp: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_warm_up'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id']),
    );
  }

  @override
  $WorkoutSetsTable createAlias(String alias) {
    return $WorkoutSetsTable(attachedDatabase, alias);
  }
}

class WorkoutSet extends DataClass implements Insertable<WorkoutSet> {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int setOrder;
  final double weight;
  final int reps;
  final double? rpe;
  final int timestamp;
  final bool isWarmUp;
  final String? groupId;
  const WorkoutSet(
      {required this.id,
      required this.workoutId,
      required this.exerciseId,
      required this.setOrder,
      required this.weight,
      required this.reps,
      this.rpe,
      required this.timestamp,
      required this.isWarmUp,
      this.groupId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_id'] = Variable<String>(workoutId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['set_order'] = Variable<int>(setOrder);
    map['weight'] = Variable<double>(weight);
    map['reps'] = Variable<int>(reps);
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<double>(rpe);
    }
    map['timestamp'] = Variable<int>(timestamp);
    map['is_warm_up'] = Variable<bool>(isWarmUp);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    return map;
  }

  WorkoutSetsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      exerciseId: Value(exerciseId),
      setOrder: Value(setOrder),
      weight: Value(weight),
      reps: Value(reps),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      timestamp: Value(timestamp),
      isWarmUp: Value(isWarmUp),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
    );
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSet(
      id: serializer.fromJson<String>(json['id']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      setOrder: serializer.fromJson<int>(json['setOrder']),
      weight: serializer.fromJson<double>(json['weight']),
      reps: serializer.fromJson<int>(json['reps']),
      rpe: serializer.fromJson<double?>(json['rpe']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      isWarmUp: serializer.fromJson<bool>(json['isWarmUp']),
      groupId: serializer.fromJson<String?>(json['groupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutId': serializer.toJson<String>(workoutId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'setOrder': serializer.toJson<int>(setOrder),
      'weight': serializer.toJson<double>(weight),
      'reps': serializer.toJson<int>(reps),
      'rpe': serializer.toJson<double?>(rpe),
      'timestamp': serializer.toJson<int>(timestamp),
      'isWarmUp': serializer.toJson<bool>(isWarmUp),
      'groupId': serializer.toJson<String?>(groupId),
    };
  }

  WorkoutSet copyWith(
          {String? id,
          String? workoutId,
          String? exerciseId,
          int? setOrder,
          double? weight,
          int? reps,
          Value<double?> rpe = const Value.absent(),
          int? timestamp,
          bool? isWarmUp,
          Value<String?> groupId = const Value.absent()}) =>
      WorkoutSet(
        id: id ?? this.id,
        workoutId: workoutId ?? this.workoutId,
        exerciseId: exerciseId ?? this.exerciseId,
        setOrder: setOrder ?? this.setOrder,
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        rpe: rpe.present ? rpe.value : this.rpe,
        timestamp: timestamp ?? this.timestamp,
        isWarmUp: isWarmUp ?? this.isWarmUp,
        groupId: groupId.present ? groupId.value : this.groupId,
      );
  WorkoutSet copyWithCompanion(WorkoutSetsCompanion data) {
    return WorkoutSet(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      setOrder: data.setOrder.present ? data.setOrder.value : this.setOrder,
      weight: data.weight.present ? data.weight.value : this.weight,
      reps: data.reps.present ? data.reps.value : this.reps,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isWarmUp: data.isWarmUp.present ? data.isWarmUp.value : this.isWarmUp,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSet(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setOrder: $setOrder, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rpe: $rpe, ')
          ..write('timestamp: $timestamp, ')
          ..write('isWarmUp: $isWarmUp, ')
          ..write('groupId: $groupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workoutId, exerciseId, setOrder, weight,
      reps, rpe, timestamp, isWarmUp, groupId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSet &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.exerciseId == this.exerciseId &&
          other.setOrder == this.setOrder &&
          other.weight == this.weight &&
          other.reps == this.reps &&
          other.rpe == this.rpe &&
          other.timestamp == this.timestamp &&
          other.isWarmUp == this.isWarmUp &&
          other.groupId == this.groupId);
}

class WorkoutSetsCompanion extends UpdateCompanion<WorkoutSet> {
  final Value<String> id;
  final Value<String> workoutId;
  final Value<String> exerciseId;
  final Value<int> setOrder;
  final Value<double> weight;
  final Value<int> reps;
  final Value<double?> rpe;
  final Value<int> timestamp;
  final Value<bool> isWarmUp;
  final Value<String?> groupId;
  final Value<int> rowid;
  const WorkoutSetsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setOrder = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.rpe = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isWarmUp = const Value.absent(),
    this.groupId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSetsCompanion.insert({
    required String id,
    required String workoutId,
    required String exerciseId,
    required int setOrder,
    required double weight,
    required int reps,
    this.rpe = const Value.absent(),
    required int timestamp,
    this.isWarmUp = const Value.absent(),
    this.groupId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workoutId = Value(workoutId),
        exerciseId = Value(exerciseId),
        setOrder = Value(setOrder),
        weight = Value(weight),
        reps = Value(reps),
        timestamp = Value(timestamp);
  static Insertable<WorkoutSet> custom({
    Expression<String>? id,
    Expression<String>? workoutId,
    Expression<String>? exerciseId,
    Expression<int>? setOrder,
    Expression<double>? weight,
    Expression<int>? reps,
    Expression<double>? rpe,
    Expression<int>? timestamp,
    Expression<bool>? isWarmUp,
    Expression<String>? groupId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setOrder != null) 'set_order': setOrder,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (rpe != null) 'rpe': rpe,
      if (timestamp != null) 'timestamp': timestamp,
      if (isWarmUp != null) 'is_warm_up': isWarmUp,
      if (groupId != null) 'group_id': groupId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? workoutId,
      Value<String>? exerciseId,
      Value<int>? setOrder,
      Value<double>? weight,
      Value<int>? reps,
      Value<double?>? rpe,
      Value<int>? timestamp,
      Value<bool>? isWarmUp,
      Value<String?>? groupId,
      Value<int>? rowid}) {
    return WorkoutSetsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      setOrder: setOrder ?? this.setOrder,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      timestamp: timestamp ?? this.timestamp,
      isWarmUp: isWarmUp ?? this.isWarmUp,
      groupId: groupId ?? this.groupId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (setOrder.present) {
      map['set_order'] = Variable<int>(setOrder.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<double>(rpe.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (isWarmUp.present) {
      map['is_warm_up'] = Variable<bool>(isWarmUp.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setOrder: $setOrder, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rpe: $rpe, ')
          ..write('timestamp: $timestamp, ')
          ..write('isWarmUp: $isWarmUp, ')
          ..write('groupId: $groupId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardioSessionsTable extends CardioSessions
    with TableInfo<$CardioSessionsTable, CardioSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardioSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workoutIdMeta =
      const VerificationMeta('workoutId');
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
      'workout_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES workouts (id)'));
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _distanceMetersMeta =
      const VerificationMeta('distanceMeters');
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
      'distance_meters', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _inclineMeta =
      const VerificationMeta('incline');
  @override
  late final GeneratedColumn<double> incline = GeneratedColumn<double>(
      'incline', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgHeartRateMeta =
      const VerificationMeta('avgHeartRate');
  @override
  late final GeneratedColumn<int> avgHeartRate = GeneratedColumn<int>(
      'avg_heart_rate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        workoutId,
        exerciseId,
        durationSeconds,
        distanceMeters,
        incline,
        avgHeartRate
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cardio_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<CardioSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(_workoutIdMeta,
          workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta));
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
          _distanceMetersMeta,
          distanceMeters.isAcceptableOrUnknown(
              data['distance_meters']!, _distanceMetersMeta));
    }
    if (data.containsKey('incline')) {
      context.handle(_inclineMeta,
          incline.isAcceptableOrUnknown(data['incline']!, _inclineMeta));
    }
    if (data.containsKey('avg_heart_rate')) {
      context.handle(
          _avgHeartRateMeta,
          avgHeartRate.isAcceptableOrUnknown(
              data['avg_heart_rate']!, _avgHeartRateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardioSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardioSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workoutId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      distanceMeters: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance_meters']),
      incline: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}incline']),
      avgHeartRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}avg_heart_rate']),
    );
  }

  @override
  $CardioSessionsTable createAlias(String alias) {
    return $CardioSessionsTable(attachedDatabase, alias);
  }
}

class CardioSession extends DataClass implements Insertable<CardioSession> {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int durationSeconds;
  final double? distanceMeters;
  final double? incline;
  final int? avgHeartRate;
  const CardioSession(
      {required this.id,
      required this.workoutId,
      required this.exerciseId,
      required this.durationSeconds,
      this.distanceMeters,
      this.incline,
      this.avgHeartRate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_id'] = Variable<String>(workoutId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || distanceMeters != null) {
      map['distance_meters'] = Variable<double>(distanceMeters);
    }
    if (!nullToAbsent || incline != null) {
      map['incline'] = Variable<double>(incline);
    }
    if (!nullToAbsent || avgHeartRate != null) {
      map['avg_heart_rate'] = Variable<int>(avgHeartRate);
    }
    return map;
  }

  CardioSessionsCompanion toCompanion(bool nullToAbsent) {
    return CardioSessionsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      exerciseId: Value(exerciseId),
      durationSeconds: Value(durationSeconds),
      distanceMeters: distanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceMeters),
      incline: incline == null && nullToAbsent
          ? const Value.absent()
          : Value(incline),
      avgHeartRate: avgHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHeartRate),
    );
  }

  factory CardioSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardioSession(
      id: serializer.fromJson<String>(json['id']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      distanceMeters: serializer.fromJson<double?>(json['distanceMeters']),
      incline: serializer.fromJson<double?>(json['incline']),
      avgHeartRate: serializer.fromJson<int?>(json['avgHeartRate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutId': serializer.toJson<String>(workoutId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'distanceMeters': serializer.toJson<double?>(distanceMeters),
      'incline': serializer.toJson<double?>(incline),
      'avgHeartRate': serializer.toJson<int?>(avgHeartRate),
    };
  }

  CardioSession copyWith(
          {String? id,
          String? workoutId,
          String? exerciseId,
          int? durationSeconds,
          Value<double?> distanceMeters = const Value.absent(),
          Value<double?> incline = const Value.absent(),
          Value<int?> avgHeartRate = const Value.absent()}) =>
      CardioSession(
        id: id ?? this.id,
        workoutId: workoutId ?? this.workoutId,
        exerciseId: exerciseId ?? this.exerciseId,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        distanceMeters:
            distanceMeters.present ? distanceMeters.value : this.distanceMeters,
        incline: incline.present ? incline.value : this.incline,
        avgHeartRate:
            avgHeartRate.present ? avgHeartRate.value : this.avgHeartRate,
      );
  CardioSession copyWithCompanion(CardioSessionsCompanion data) {
    return CardioSession(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      incline: data.incline.present ? data.incline.value : this.incline,
      avgHeartRate: data.avgHeartRate.present
          ? data.avgHeartRate.value
          : this.avgHeartRate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardioSession(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('incline: $incline, ')
          ..write('avgHeartRate: $avgHeartRate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workoutId, exerciseId, durationSeconds,
      distanceMeters, incline, avgHeartRate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardioSession &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.exerciseId == this.exerciseId &&
          other.durationSeconds == this.durationSeconds &&
          other.distanceMeters == this.distanceMeters &&
          other.incline == this.incline &&
          other.avgHeartRate == this.avgHeartRate);
}

class CardioSessionsCompanion extends UpdateCompanion<CardioSession> {
  final Value<String> id;
  final Value<String> workoutId;
  final Value<String> exerciseId;
  final Value<int> durationSeconds;
  final Value<double?> distanceMeters;
  final Value<double?> incline;
  final Value<int?> avgHeartRate;
  final Value<int> rowid;
  const CardioSessionsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.incline = const Value.absent(),
    this.avgHeartRate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardioSessionsCompanion.insert({
    required String id,
    required String workoutId,
    required String exerciseId,
    required int durationSeconds,
    this.distanceMeters = const Value.absent(),
    this.incline = const Value.absent(),
    this.avgHeartRate = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workoutId = Value(workoutId),
        exerciseId = Value(exerciseId),
        durationSeconds = Value(durationSeconds);
  static Insertable<CardioSession> custom({
    Expression<String>? id,
    Expression<String>? workoutId,
    Expression<String>? exerciseId,
    Expression<int>? durationSeconds,
    Expression<double>? distanceMeters,
    Expression<double>? incline,
    Expression<int>? avgHeartRate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (incline != null) 'incline': incline,
      if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardioSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? workoutId,
      Value<String>? exerciseId,
      Value<int>? durationSeconds,
      Value<double?>? distanceMeters,
      Value<double?>? incline,
      Value<int?>? avgHeartRate,
      Value<int>? rowid}) {
    return CardioSessionsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      incline: incline ?? this.incline,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (incline.present) {
      map['incline'] = Variable<double>(incline.value);
    }
    if (avgHeartRate.present) {
      map['avg_heart_rate'] = Variable<int>(avgHeartRate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardioSessionsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('incline: $incline, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonalRecordsTable extends PersonalRecords
    with TableInfo<$PersonalRecordsTable, PersonalRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _recordTypeMeta =
      const VerificationMeta('recordType');
  @override
  late final GeneratedColumn<String> recordType = GeneratedColumn<String>(
      'record_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _achievedAtMeta =
      const VerificationMeta('achievedAt');
  @override
  late final GeneratedColumn<int> achievedAt = GeneratedColumn<int>(
      'achieved_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _workoutSetIdMeta =
      const VerificationMeta('workoutSetId');
  @override
  late final GeneratedColumn<String> workoutSetId = GeneratedColumn<String>(
      'workout_set_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES workout_sets (id)'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, exerciseId, recordType, value, achievedAt, workoutSetId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_records';
  @override
  VerificationContext validateIntegrity(Insertable<PersonalRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('record_type')) {
      context.handle(
          _recordTypeMeta,
          recordType.isAcceptableOrUnknown(
              data['record_type']!, _recordTypeMeta));
    } else if (isInserting) {
      context.missing(_recordTypeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('achieved_at')) {
      context.handle(
          _achievedAtMeta,
          achievedAt.isAcceptableOrUnknown(
              data['achieved_at']!, _achievedAtMeta));
    } else if (isInserting) {
      context.missing(_achievedAtMeta);
    }
    if (data.containsKey('workout_set_id')) {
      context.handle(
          _workoutSetIdMeta,
          workoutSetId.isAcceptableOrUnknown(
              data['workout_set_id']!, _workoutSetIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      recordType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_type'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      achievedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}achieved_at'])!,
      workoutSetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_set_id']),
    );
  }

  @override
  $PersonalRecordsTable createAlias(String alias) {
    return $PersonalRecordsTable(attachedDatabase, alias);
  }
}

class PersonalRecord extends DataClass implements Insertable<PersonalRecord> {
  final String id;
  final String exerciseId;
  final String recordType;
  final double value;
  final int achievedAt;
  final String? workoutSetId;
  const PersonalRecord(
      {required this.id,
      required this.exerciseId,
      required this.recordType,
      required this.value,
      required this.achievedAt,
      this.workoutSetId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['record_type'] = Variable<String>(recordType);
    map['value'] = Variable<double>(value);
    map['achieved_at'] = Variable<int>(achievedAt);
    if (!nullToAbsent || workoutSetId != null) {
      map['workout_set_id'] = Variable<String>(workoutSetId);
    }
    return map;
  }

  PersonalRecordsCompanion toCompanion(bool nullToAbsent) {
    return PersonalRecordsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      recordType: Value(recordType),
      value: Value(value),
      achievedAt: Value(achievedAt),
      workoutSetId: workoutSetId == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutSetId),
    );
  }

  factory PersonalRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalRecord(
      id: serializer.fromJson<String>(json['id']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      recordType: serializer.fromJson<String>(json['recordType']),
      value: serializer.fromJson<double>(json['value']),
      achievedAt: serializer.fromJson<int>(json['achievedAt']),
      workoutSetId: serializer.fromJson<String?>(json['workoutSetId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'recordType': serializer.toJson<String>(recordType),
      'value': serializer.toJson<double>(value),
      'achievedAt': serializer.toJson<int>(achievedAt),
      'workoutSetId': serializer.toJson<String?>(workoutSetId),
    };
  }

  PersonalRecord copyWith(
          {String? id,
          String? exerciseId,
          String? recordType,
          double? value,
          int? achievedAt,
          Value<String?> workoutSetId = const Value.absent()}) =>
      PersonalRecord(
        id: id ?? this.id,
        exerciseId: exerciseId ?? this.exerciseId,
        recordType: recordType ?? this.recordType,
        value: value ?? this.value,
        achievedAt: achievedAt ?? this.achievedAt,
        workoutSetId:
            workoutSetId.present ? workoutSetId.value : this.workoutSetId,
      );
  PersonalRecord copyWithCompanion(PersonalRecordsCompanion data) {
    return PersonalRecord(
      id: data.id.present ? data.id.value : this.id,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      recordType:
          data.recordType.present ? data.recordType.value : this.recordType,
      value: data.value.present ? data.value.value : this.value,
      achievedAt:
          data.achievedAt.present ? data.achievedAt.value : this.achievedAt,
      workoutSetId: data.workoutSetId.present
          ? data.workoutSetId.value
          : this.workoutSetId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalRecord(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('recordType: $recordType, ')
          ..write('value: $value, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('workoutSetId: $workoutSetId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, exerciseId, recordType, value, achievedAt, workoutSetId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalRecord &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.recordType == this.recordType &&
          other.value == this.value &&
          other.achievedAt == this.achievedAt &&
          other.workoutSetId == this.workoutSetId);
}

class PersonalRecordsCompanion extends UpdateCompanion<PersonalRecord> {
  final Value<String> id;
  final Value<String> exerciseId;
  final Value<String> recordType;
  final Value<double> value;
  final Value<int> achievedAt;
  final Value<String?> workoutSetId;
  final Value<int> rowid;
  const PersonalRecordsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.recordType = const Value.absent(),
    this.value = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.workoutSetId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonalRecordsCompanion.insert({
    required String id,
    required String exerciseId,
    required String recordType,
    required double value,
    required int achievedAt,
    this.workoutSetId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        exerciseId = Value(exerciseId),
        recordType = Value(recordType),
        value = Value(value),
        achievedAt = Value(achievedAt);
  static Insertable<PersonalRecord> custom({
    Expression<String>? id,
    Expression<String>? exerciseId,
    Expression<String>? recordType,
    Expression<double>? value,
    Expression<int>? achievedAt,
    Expression<String>? workoutSetId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (recordType != null) 'record_type': recordType,
      if (value != null) 'value': value,
      if (achievedAt != null) 'achieved_at': achievedAt,
      if (workoutSetId != null) 'workout_set_id': workoutSetId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonalRecordsCompanion copyWith(
      {Value<String>? id,
      Value<String>? exerciseId,
      Value<String>? recordType,
      Value<double>? value,
      Value<int>? achievedAt,
      Value<String?>? workoutSetId,
      Value<int>? rowid}) {
    return PersonalRecordsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      recordType: recordType ?? this.recordType,
      value: value ?? this.value,
      achievedAt: achievedAt ?? this.achievedAt,
      workoutSetId: workoutSetId ?? this.workoutSetId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (recordType.present) {
      map['record_type'] = Variable<String>(recordType.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (achievedAt.present) {
      map['achieved_at'] = Variable<int>(achievedAt.value);
    }
    if (workoutSetId.present) {
      map['workout_set_id'] = Variable<String>(workoutSetId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalRecordsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('recordType: $recordType, ')
          ..write('value: $value, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('workoutSetId: $workoutSetId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutTemplatesTable extends WorkoutTemplates
    with TableInfo<$WorkoutTemplatesTable, WorkoutTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_templates';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WorkoutTemplatesTable createAlias(String alias) {
    return $WorkoutTemplatesTable(attachedDatabase, alias);
  }
}

class WorkoutTemplate extends DataClass implements Insertable<WorkoutTemplate> {
  final String id;
  final String name;
  final int createdAt;
  final int updatedAt;
  const WorkoutTemplate(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  WorkoutTemplatesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplate(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  WorkoutTemplate copyWith(
          {String? id, String? name, int? createdAt, int? updatedAt}) =>
      WorkoutTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WorkoutTemplate copyWithCompanion(WorkoutTemplatesCompanion data) {
    return WorkoutTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorkoutTemplatesCompanion extends UpdateCompanion<WorkoutTemplate> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const WorkoutTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutTemplatesCompanion.insert({
    required String id,
    required String name,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<WorkoutTemplate> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutTemplatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return WorkoutTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplateExercisesTable extends TemplateExercises
    with TableInfo<$TemplateExercisesTable, TemplateExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _templateIdMeta =
      const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
      'template_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workout_templates (id)'));
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _exerciseNameMeta =
      const VerificationMeta('exerciseName');
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
      'exercise_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _targetSetsMeta =
      const VerificationMeta('targetSets');
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
      'target_sets', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetRepsMeta =
      const VerificationMeta('targetReps');
  @override
  late final GeneratedColumn<int> targetReps = GeneratedColumn<int>(
      'target_reps', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        templateId,
        exerciseId,
        exerciseName,
        targetSets,
        targetReps,
        orderIndex
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<TemplateExercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
          _templateIdMeta,
          templateId.isAcceptableOrUnknown(
              data['template_id']!, _templateIdMeta));
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('exercise_name')) {
      context.handle(
          _exerciseNameMeta,
          exerciseName.isAcceptableOrUnknown(
              data['exercise_name']!, _exerciseNameMeta));
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('target_sets')) {
      context.handle(
          _targetSetsMeta,
          targetSets.isAcceptableOrUnknown(
              data['target_sets']!, _targetSetsMeta));
    } else if (isInserting) {
      context.missing(_targetSetsMeta);
    }
    if (data.containsKey('target_reps')) {
      context.handle(
          _targetRepsMeta,
          targetReps.isAcceptableOrUnknown(
              data['target_reps']!, _targetRepsMeta));
    } else if (isInserting) {
      context.missing(_targetRepsMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateExercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      templateId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      exerciseName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_name'])!,
      targetSets: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_sets'])!,
      targetReps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_reps'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
    );
  }

  @override
  $TemplateExercisesTable createAlias(String alias) {
    return $TemplateExercisesTable(attachedDatabase, alias);
  }
}

class TemplateExercise extends DataClass
    implements Insertable<TemplateExercise> {
  final String id;
  final String templateId;
  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final int orderIndex;
  const TemplateExercise(
      {required this.id,
      required this.templateId,
      required this.exerciseId,
      required this.exerciseName,
      required this.targetSets,
      required this.targetReps,
      required this.orderIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['exercise_name'] = Variable<String>(exerciseName);
    map['target_sets'] = Variable<int>(targetSets);
    map['target_reps'] = Variable<int>(targetReps);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  TemplateExercisesCompanion toCompanion(bool nullToAbsent) {
    return TemplateExercisesCompanion(
      id: Value(id),
      templateId: Value(templateId),
      exerciseId: Value(exerciseId),
      exerciseName: Value(exerciseName),
      targetSets: Value(targetSets),
      targetReps: Value(targetReps),
      orderIndex: Value(orderIndex),
    );
  }

  factory TemplateExercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateExercise(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      targetSets: serializer.fromJson<int>(json['targetSets']),
      targetReps: serializer.fromJson<int>(json['targetReps']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String>(templateId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'targetSets': serializer.toJson<int>(targetSets),
      'targetReps': serializer.toJson<int>(targetReps),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  TemplateExercise copyWith(
          {String? id,
          String? templateId,
          String? exerciseId,
          String? exerciseName,
          int? targetSets,
          int? targetReps,
          int? orderIndex}) =>
      TemplateExercise(
        id: id ?? this.id,
        templateId: templateId ?? this.templateId,
        exerciseId: exerciseId ?? this.exerciseId,
        exerciseName: exerciseName ?? this.exerciseName,
        targetSets: targetSets ?? this.targetSets,
        targetReps: targetReps ?? this.targetReps,
        orderIndex: orderIndex ?? this.orderIndex,
      );
  TemplateExercise copyWithCompanion(TemplateExercisesCompanion data) {
    return TemplateExercise(
      id: data.id.present ? data.id.value : this.id,
      templateId:
          data.templateId.present ? data.templateId.value : this.templateId,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      targetSets:
          data.targetSets.present ? data.targetSets.value : this.targetSets,
      targetReps:
          data.targetReps.present ? data.targetReps.value : this.targetReps,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercise(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, templateId, exerciseId, exerciseName,
      targetSets, targetReps, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateExercise &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.exerciseId == this.exerciseId &&
          other.exerciseName == this.exerciseName &&
          other.targetSets == this.targetSets &&
          other.targetReps == this.targetReps &&
          other.orderIndex == this.orderIndex);
}

class TemplateExercisesCompanion extends UpdateCompanion<TemplateExercise> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<String> exerciseId;
  final Value<String> exerciseName;
  final Value<int> targetSets;
  final Value<int> targetReps;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const TemplateExercisesCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateExercisesCompanion.insert({
    required String id,
    required String templateId,
    required String exerciseId,
    required String exerciseName,
    required int targetSets,
    required int targetReps,
    required int orderIndex,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        templateId = Value(templateId),
        exerciseId = Value(exerciseId),
        exerciseName = Value(exerciseName),
        targetSets = Value(targetSets),
        targetReps = Value(targetReps),
        orderIndex = Value(orderIndex);
  static Insertable<TemplateExercise> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? exerciseId,
    Expression<String>? exerciseName,
    Expression<int>? targetSets,
    Expression<int>? targetReps,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (targetSets != null) 'target_sets': targetSets,
      if (targetReps != null) 'target_reps': targetReps,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateExercisesCompanion copyWith(
      {Value<String>? id,
      Value<String>? templateId,
      Value<String>? exerciseId,
      Value<String>? exerciseName,
      Value<int>? targetSets,
      Value<int>? targetReps,
      Value<int>? orderIndex,
      Value<int>? rowid}) {
    return TemplateExercisesCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<int>(targetReps.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercisesCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BodyMetricsTable bodyMetrics = $BodyMetricsTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $WorkoutSetsTable workoutSets = $WorkoutSetsTable(this);
  late final $CardioSessionsTable cardioSessions = $CardioSessionsTable(this);
  late final $PersonalRecordsTable personalRecords =
      $PersonalRecordsTable(this);
  late final $WorkoutTemplatesTable workoutTemplates =
      $WorkoutTemplatesTable(this);
  late final $TemplateExercisesTable templateExercises =
      $TemplateExercisesTable(this);
  late final Index idxWorkoutSetsExerciseTimestamp = Index(
      'idx_workout_sets_exercise_timestamp',
      'CREATE INDEX idx_workout_sets_exercise_timestamp ON workout_sets (exercise_id, timestamp)');
  late final Index idxWorkoutSetsWorkoutOrder = Index(
      'idx_workout_sets_workout_order',
      'CREATE INDEX idx_workout_sets_workout_order ON workout_sets (workout_id, set_order)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        bodyMetrics,
        exercises,
        workouts,
        workoutSets,
        cardioSessions,
        personalRecords,
        workoutTemplates,
        templateExercises,
        idxWorkoutSetsExerciseTimestamp,
        idxWorkoutSetsWorkoutOrder
      ];
}

typedef $$BodyMetricsTableCreateCompanionBuilder = BodyMetricsCompanion
    Function({
  required String id,
  required int date,
  required double weight,
  Value<double?> bodyFatPercent,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$BodyMetricsTableUpdateCompanionBuilder = BodyMetricsCompanion
    Function({
  Value<String> id,
  Value<int> date,
  Value<double> weight,
  Value<double?> bodyFatPercent,
  Value<String?> notes,
  Value<int> rowid,
});

class $$BodyMetricsTableFilterComposer
    extends Composer<_$AppDatabase, $BodyMetricsTable> {
  $$BodyMetricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bodyFatPercent => $composableBuilder(
      column: $table.bodyFatPercent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));
}

class $$BodyMetricsTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyMetricsTable> {
  $$BodyMetricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bodyFatPercent => $composableBuilder(
      column: $table.bodyFatPercent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$BodyMetricsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyMetricsTable> {
  $$BodyMetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPercent => $composableBuilder(
      column: $table.bodyFatPercent, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$BodyMetricsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BodyMetricsTable,
    BodyMetric,
    $$BodyMetricsTableFilterComposer,
    $$BodyMetricsTableOrderingComposer,
    $$BodyMetricsTableAnnotationComposer,
    $$BodyMetricsTableCreateCompanionBuilder,
    $$BodyMetricsTableUpdateCompanionBuilder,
    (BodyMetric, BaseReferences<_$AppDatabase, $BodyMetricsTable, BodyMetric>),
    BodyMetric,
    PrefetchHooks Function()> {
  $$BodyMetricsTableTableManager(_$AppDatabase db, $BodyMetricsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyMetricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyMetricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyMetricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> date = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<double?> bodyFatPercent = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BodyMetricsCompanion(
            id: id,
            date: date,
            weight: weight,
            bodyFatPercent: bodyFatPercent,
            notes: notes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int date,
            required double weight,
            Value<double?> bodyFatPercent = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BodyMetricsCompanion.insert(
            id: id,
            date: date,
            weight: weight,
            bodyFatPercent: bodyFatPercent,
            notes: notes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BodyMetricsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BodyMetricsTable,
    BodyMetric,
    $$BodyMetricsTableFilterComposer,
    $$BodyMetricsTableOrderingComposer,
    $$BodyMetricsTableAnnotationComposer,
    $$BodyMetricsTableCreateCompanionBuilder,
    $$BodyMetricsTableUpdateCompanionBuilder,
    (BodyMetric, BaseReferences<_$AppDatabase, $BodyMetricsTable, BodyMetric>),
    BodyMetric,
    PrefetchHooks Function()>;
typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  required String id,
  required String name,
  required String category,
  required String muscleGroup,
  required String equipmentType,
  Value<bool> isCustom,
  Value<String?> imageAsset,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> category,
  Value<String> muscleGroup,
  Value<String> equipmentType,
  Value<bool> isCustom,
  Value<String?> imageAsset,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>>
      _workoutSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.workoutSets,
          aliasName:
              $_aliasNameGenerator(db.exercises.id, db.workoutSets.exerciseId));

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager($_db, $_db.workoutSets)
        .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CardioSessionsTable, List<CardioSession>>
      _cardioSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.cardioSessions,
              aliasName: $_aliasNameGenerator(
                  db.exercises.id, db.cardioSessions.exerciseId));

  $$CardioSessionsTableProcessedTableManager get cardioSessionsRefs {
    final manager = $$CardioSessionsTableTableManager($_db, $_db.cardioSessions)
        .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardioSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PersonalRecordsTable, List<PersonalRecord>>
      _personalRecordsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.personalRecords,
              aliasName: $_aliasNameGenerator(
                  db.exercises.id, db.personalRecords.exerciseId));

  $$PersonalRecordsTableProcessedTableManager get personalRecordsRefs {
    final manager = $$PersonalRecordsTableTableManager(
            $_db, $_db.personalRecords)
        .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_personalRecordsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TemplateExercisesTable, List<TemplateExercise>>
      _templateExercisesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.templateExercises,
              aliasName: $_aliasNameGenerator(
                  db.exercises.id, db.templateExercises.exerciseId));

  $$TemplateExercisesTableProcessedTableManager get templateExercisesRefs {
    final manager = $$TemplateExercisesTableTableManager(
            $_db, $_db.templateExercises)
        .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_templateExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get muscleGroup => $composableBuilder(
      column: $table.muscleGroup, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equipmentType => $composableBuilder(
      column: $table.equipmentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageAsset => $composableBuilder(
      column: $table.imageAsset, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> workoutSetsRefs(
      Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> cardioSessionsRefs(
      Expression<bool> Function($$CardioSessionsTableFilterComposer f) f) {
    final $$CardioSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cardioSessions,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardioSessionsTableFilterComposer(
              $db: $db,
              $table: $db.cardioSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> personalRecordsRefs(
      Expression<bool> Function($$PersonalRecordsTableFilterComposer f) f) {
    final $$PersonalRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.personalRecords,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonalRecordsTableFilterComposer(
              $db: $db,
              $table: $db.personalRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> templateExercisesRefs(
      Expression<bool> Function($$TemplateExercisesTableFilterComposer f) f) {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.templateExercises,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TemplateExercisesTableFilterComposer(
              $db: $db,
              $table: $db.templateExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get muscleGroup => $composableBuilder(
      column: $table.muscleGroup, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equipmentType => $composableBuilder(
      column: $table.equipmentType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageAsset => $composableBuilder(
      column: $table.imageAsset, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get muscleGroup => $composableBuilder(
      column: $table.muscleGroup, builder: (column) => column);

  GeneratedColumn<String> get equipmentType => $composableBuilder(
      column: $table.equipmentType, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<String> get imageAsset => $composableBuilder(
      column: $table.imageAsset, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> workoutSetsRefs<T extends Object>(
      Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> cardioSessionsRefs<T extends Object>(
      Expression<T> Function($$CardioSessionsTableAnnotationComposer a) f) {
    final $$CardioSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cardioSessions,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardioSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.cardioSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> personalRecordsRefs<T extends Object>(
      Expression<T> Function($$PersonalRecordsTableAnnotationComposer a) f) {
    final $$PersonalRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.personalRecords,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonalRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.personalRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> templateExercisesRefs<T extends Object>(
      Expression<T> Function($$TemplateExercisesTableAnnotationComposer a) f) {
    final $$TemplateExercisesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.templateExercises,
            getReferencedColumn: (t) => t.exerciseId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TemplateExercisesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.templateExercises,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, $$ExercisesTableReferences),
    Exercise,
    PrefetchHooks Function(
        {bool workoutSetsRefs,
        bool cardioSessionsRefs,
        bool personalRecordsRefs,
        bool templateExercisesRefs})> {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> muscleGroup = const Value.absent(),
            Value<String> equipmentType = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<String?> imageAsset = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExercisesCompanion(
            id: id,
            name: name,
            category: category,
            muscleGroup: muscleGroup,
            equipmentType: equipmentType,
            isCustom: isCustom,
            imageAsset: imageAsset,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String category,
            required String muscleGroup,
            required String equipmentType,
            Value<bool> isCustom = const Value.absent(),
            Value<String?> imageAsset = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExercisesCompanion.insert(
            id: id,
            name: name,
            category: category,
            muscleGroup: muscleGroup,
            equipmentType: equipmentType,
            isCustom: isCustom,
            imageAsset: imageAsset,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {workoutSetsRefs = false,
              cardioSessionsRefs = false,
              personalRecordsRefs = false,
              templateExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (workoutSetsRefs) db.workoutSets,
                if (cardioSessionsRefs) db.cardioSessions,
                if (personalRecordsRefs) db.personalRecords,
                if (templateExercisesRefs) db.templateExercises
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutSetsRefs)
                    await $_getPrefetchedData<Exercise, $ExercisesTable,
                            WorkoutSet>(
                        currentTable: table,
                        referencedTable: $$ExercisesTableReferences
                            ._workoutSetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .workoutSetsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items),
                  if (cardioSessionsRefs)
                    await $_getPrefetchedData<Exercise, $ExercisesTable,
                            CardioSession>(
                        currentTable: table,
                        referencedTable: $$ExercisesTableReferences
                            ._cardioSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .cardioSessionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items),
                  if (personalRecordsRefs)
                    await $_getPrefetchedData<Exercise, $ExercisesTable,
                            PersonalRecord>(
                        currentTable: table,
                        referencedTable: $$ExercisesTableReferences
                            ._personalRecordsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .personalRecordsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items),
                  if (templateExercisesRefs)
                    await $_getPrefetchedData<Exercise, $ExercisesTable,
                            TemplateExercise>(
                        currentTable: table,
                        referencedTable: $$ExercisesTableReferences
                            ._templateExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .templateExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, $$ExercisesTableReferences),
    Exercise,
    PrefetchHooks Function(
        {bool workoutSetsRefs,
        bool cardioSessionsRefs,
        bool personalRecordsRefs,
        bool templateExercisesRefs})>;
typedef $$WorkoutsTableCreateCompanionBuilder = WorkoutsCompanion Function({
  required String id,
  required int startedAt,
  Value<int?> completedAt,
  Value<String?> templateId,
  Value<String?> notes,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$WorkoutsTableUpdateCompanionBuilder = WorkoutsCompanion Function({
  Value<String> id,
  Value<int> startedAt,
  Value<int?> completedAt,
  Value<String?> templateId,
  Value<String?> notes,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $$WorkoutsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutsTable, Workout> {
  $$WorkoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>>
      _workoutSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.workoutSets,
          aliasName:
              $_aliasNameGenerator(db.workouts.id, db.workoutSets.workoutId));

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager($_db, $_db.workoutSets)
        .filter((f) => f.workoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CardioSessionsTable, List<CardioSession>>
      _cardioSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.cardioSessions,
              aliasName: $_aliasNameGenerator(
                  db.workouts.id, db.cardioSessions.workoutId));

  $$CardioSessionsTableProcessedTableManager get cardioSessionsRefs {
    final manager = $$CardioSessionsTableTableManager($_db, $_db.cardioSessions)
        .filter((f) => f.workoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardioSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> workoutSetsRefs(
      Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.workoutId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> cardioSessionsRefs(
      Expression<bool> Function($$CardioSessionsTableFilterComposer f) f) {
    final $$CardioSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cardioSessions,
        getReferencedColumn: (t) => t.workoutId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardioSessionsTableFilterComposer(
              $db: $db,
              $table: $db.cardioSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> workoutSetsRefs<T extends Object>(
      Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.workoutId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> cardioSessionsRefs<T extends Object>(
      Expression<T> Function($$CardioSessionsTableAnnotationComposer a) f) {
    final $$CardioSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cardioSessions,
        getReferencedColumn: (t) => t.workoutId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardioSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.cardioSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutsTable,
    Workout,
    $$WorkoutsTableFilterComposer,
    $$WorkoutsTableOrderingComposer,
    $$WorkoutsTableAnnotationComposer,
    $$WorkoutsTableCreateCompanionBuilder,
    $$WorkoutsTableUpdateCompanionBuilder,
    (Workout, $$WorkoutsTableReferences),
    Workout,
    PrefetchHooks Function({bool workoutSetsRefs, bool cardioSessionsRefs})> {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> startedAt = const Value.absent(),
            Value<int?> completedAt = const Value.absent(),
            Value<String?> templateId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutsCompanion(
            id: id,
            startedAt: startedAt,
            completedAt: completedAt,
            templateId: templateId,
            notes: notes,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int startedAt,
            Value<int?> completedAt = const Value.absent(),
            Value<String?> templateId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutsCompanion.insert(
            id: id,
            startedAt: startedAt,
            completedAt: completedAt,
            templateId: templateId,
            notes: notes,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$WorkoutsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {workoutSetsRefs = false, cardioSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (workoutSetsRefs) db.workoutSets,
                if (cardioSessionsRefs) db.cardioSessions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutSetsRefs)
                    await $_getPrefetchedData<Workout, $WorkoutsTable,
                            WorkoutSet>(
                        currentTable: table,
                        referencedTable:
                            $$WorkoutsTableReferences._workoutSetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutsTableReferences(db, table, p0)
                                .workoutSetsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.workoutId == item.id),
                        typedResults: items),
                  if (cardioSessionsRefs)
                    await $_getPrefetchedData<Workout, $WorkoutsTable,
                            CardioSession>(
                        currentTable: table,
                        referencedTable: $$WorkoutsTableReferences
                            ._cardioSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutsTableReferences(db, table, p0)
                                .cardioSessionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.workoutId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutsTable,
    Workout,
    $$WorkoutsTableFilterComposer,
    $$WorkoutsTableOrderingComposer,
    $$WorkoutsTableAnnotationComposer,
    $$WorkoutsTableCreateCompanionBuilder,
    $$WorkoutsTableUpdateCompanionBuilder,
    (Workout, $$WorkoutsTableReferences),
    Workout,
    PrefetchHooks Function({bool workoutSetsRefs, bool cardioSessionsRefs})>;
typedef $$WorkoutSetsTableCreateCompanionBuilder = WorkoutSetsCompanion
    Function({
  required String id,
  required String workoutId,
  required String exerciseId,
  required int setOrder,
  required double weight,
  required int reps,
  Value<double?> rpe,
  required int timestamp,
  Value<bool> isWarmUp,
  Value<String?> groupId,
  Value<int> rowid,
});
typedef $$WorkoutSetsTableUpdateCompanionBuilder = WorkoutSetsCompanion
    Function({
  Value<String> id,
  Value<String> workoutId,
  Value<String> exerciseId,
  Value<int> setOrder,
  Value<double> weight,
  Value<int> reps,
  Value<double?> rpe,
  Value<int> timestamp,
  Value<bool> isWarmUp,
  Value<String?> groupId,
  Value<int> rowid,
});

final class $$WorkoutSetsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutSetsTable, WorkoutSet> {
  $$WorkoutSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
          $_aliasNameGenerator(db.workoutSets.workoutId, db.workouts.id));

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<String>('workout_id')!;

    final manager = $$WorkoutsTableTableManager($_db, $_db.workouts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
          $_aliasNameGenerator(db.workoutSets.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PersonalRecordsTable, List<PersonalRecord>>
      _personalRecordsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.personalRecords,
              aliasName: $_aliasNameGenerator(
                  db.workoutSets.id, db.personalRecords.workoutSetId));

  $$PersonalRecordsTableProcessedTableManager get personalRecordsRefs {
    final manager =
        $$PersonalRecordsTableTableManager($_db, $_db.personalRecords).filter(
            (f) => f.workoutSetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_personalRecordsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutSetsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get setOrder => $composableBuilder(
      column: $table.setOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rpe => $composableBuilder(
      column: $table.rpe, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isWarmUp => $composableBuilder(
      column: $table.isWarmUp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableFilterComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> personalRecordsRefs(
      Expression<bool> Function($$PersonalRecordsTableFilterComposer f) f) {
    final $$PersonalRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.personalRecords,
        getReferencedColumn: (t) => t.workoutSetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonalRecordsTableFilterComposer(
              $db: $db,
              $table: $db.personalRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get setOrder => $composableBuilder(
      column: $table.setOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rpe => $composableBuilder(
      column: $table.rpe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isWarmUp => $composableBuilder(
      column: $table.isWarmUp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableOrderingComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get setOrder =>
      $composableBuilder(column: $table.setOrder, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isWarmUp =>
      $composableBuilder(column: $table.isWarmUp, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableAnnotationComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> personalRecordsRefs<T extends Object>(
      Expression<T> Function($$PersonalRecordsTableAnnotationComposer a) f) {
    final $$PersonalRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.personalRecords,
        getReferencedColumn: (t) => t.workoutSetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonalRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.personalRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutSetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutSetsTable,
    WorkoutSet,
    $$WorkoutSetsTableFilterComposer,
    $$WorkoutSetsTableOrderingComposer,
    $$WorkoutSetsTableAnnotationComposer,
    $$WorkoutSetsTableCreateCompanionBuilder,
    $$WorkoutSetsTableUpdateCompanionBuilder,
    (WorkoutSet, $$WorkoutSetsTableReferences),
    WorkoutSet,
    PrefetchHooks Function(
        {bool workoutId, bool exerciseId, bool personalRecordsRefs})> {
  $$WorkoutSetsTableTableManager(_$AppDatabase db, $WorkoutSetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workoutId = const Value.absent(),
            Value<String> exerciseId = const Value.absent(),
            Value<int> setOrder = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<double?> rpe = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<bool> isWarmUp = const Value.absent(),
            Value<String?> groupId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutSetsCompanion(
            id: id,
            workoutId: workoutId,
            exerciseId: exerciseId,
            setOrder: setOrder,
            weight: weight,
            reps: reps,
            rpe: rpe,
            timestamp: timestamp,
            isWarmUp: isWarmUp,
            groupId: groupId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workoutId,
            required String exerciseId,
            required int setOrder,
            required double weight,
            required int reps,
            Value<double?> rpe = const Value.absent(),
            required int timestamp,
            Value<bool> isWarmUp = const Value.absent(),
            Value<String?> groupId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutSetsCompanion.insert(
            id: id,
            workoutId: workoutId,
            exerciseId: exerciseId,
            setOrder: setOrder,
            weight: weight,
            reps: reps,
            rpe: rpe,
            timestamp: timestamp,
            isWarmUp: isWarmUp,
            groupId: groupId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutSetsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {workoutId = false,
              exerciseId = false,
              personalRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (personalRecordsRefs) db.personalRecords
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (workoutId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.workoutId,
                    referencedTable:
                        $$WorkoutSetsTableReferences._workoutIdTable(db),
                    referencedColumn:
                        $$WorkoutSetsTableReferences._workoutIdTable(db).id,
                  ) as T;
                }
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$WorkoutSetsTableReferences._exerciseIdTable(db),
                    referencedColumn:
                        $$WorkoutSetsTableReferences._exerciseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (personalRecordsRefs)
                    await $_getPrefetchedData<WorkoutSet, $WorkoutSetsTable,
                            PersonalRecord>(
                        currentTable: table,
                        referencedTable: $$WorkoutSetsTableReferences
                            ._personalRecordsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutSetsTableReferences(db, table, p0)
                                .personalRecordsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.workoutSetId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutSetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutSetsTable,
    WorkoutSet,
    $$WorkoutSetsTableFilterComposer,
    $$WorkoutSetsTableOrderingComposer,
    $$WorkoutSetsTableAnnotationComposer,
    $$WorkoutSetsTableCreateCompanionBuilder,
    $$WorkoutSetsTableUpdateCompanionBuilder,
    (WorkoutSet, $$WorkoutSetsTableReferences),
    WorkoutSet,
    PrefetchHooks Function(
        {bool workoutId, bool exerciseId, bool personalRecordsRefs})>;
typedef $$CardioSessionsTableCreateCompanionBuilder = CardioSessionsCompanion
    Function({
  required String id,
  required String workoutId,
  required String exerciseId,
  required int durationSeconds,
  Value<double?> distanceMeters,
  Value<double?> incline,
  Value<int?> avgHeartRate,
  Value<int> rowid,
});
typedef $$CardioSessionsTableUpdateCompanionBuilder = CardioSessionsCompanion
    Function({
  Value<String> id,
  Value<String> workoutId,
  Value<String> exerciseId,
  Value<int> durationSeconds,
  Value<double?> distanceMeters,
  Value<double?> incline,
  Value<int?> avgHeartRate,
  Value<int> rowid,
});

final class $$CardioSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $CardioSessionsTable, CardioSession> {
  $$CardioSessionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
          $_aliasNameGenerator(db.cardioSessions.workoutId, db.workouts.id));

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<String>('workout_id')!;

    final manager = $$WorkoutsTableTableManager($_db, $_db.workouts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
          $_aliasNameGenerator(db.cardioSessions.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CardioSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $CardioSessionsTable> {
  $$CardioSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get incline => $composableBuilder(
      column: $table.incline, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get avgHeartRate => $composableBuilder(
      column: $table.avgHeartRate, builder: (column) => ColumnFilters(column));

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableFilterComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardioSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardioSessionsTable> {
  $$CardioSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get incline => $composableBuilder(
      column: $table.incline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get avgHeartRate => $composableBuilder(
      column: $table.avgHeartRate,
      builder: (column) => ColumnOrderings(column));

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableOrderingComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardioSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardioSessionsTable> {
  $$CardioSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters, builder: (column) => column);

  GeneratedColumn<double> get incline =>
      $composableBuilder(column: $table.incline, builder: (column) => column);

  GeneratedColumn<int> get avgHeartRate => $composableBuilder(
      column: $table.avgHeartRate, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableAnnotationComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardioSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardioSessionsTable,
    CardioSession,
    $$CardioSessionsTableFilterComposer,
    $$CardioSessionsTableOrderingComposer,
    $$CardioSessionsTableAnnotationComposer,
    $$CardioSessionsTableCreateCompanionBuilder,
    $$CardioSessionsTableUpdateCompanionBuilder,
    (CardioSession, $$CardioSessionsTableReferences),
    CardioSession,
    PrefetchHooks Function({bool workoutId, bool exerciseId})> {
  $$CardioSessionsTableTableManager(
      _$AppDatabase db, $CardioSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardioSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardioSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardioSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workoutId = const Value.absent(),
            Value<String> exerciseId = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<double?> distanceMeters = const Value.absent(),
            Value<double?> incline = const Value.absent(),
            Value<int?> avgHeartRate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardioSessionsCompanion(
            id: id,
            workoutId: workoutId,
            exerciseId: exerciseId,
            durationSeconds: durationSeconds,
            distanceMeters: distanceMeters,
            incline: incline,
            avgHeartRate: avgHeartRate,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workoutId,
            required String exerciseId,
            required int durationSeconds,
            Value<double?> distanceMeters = const Value.absent(),
            Value<double?> incline = const Value.absent(),
            Value<int?> avgHeartRate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardioSessionsCompanion.insert(
            id: id,
            workoutId: workoutId,
            exerciseId: exerciseId,
            durationSeconds: durationSeconds,
            distanceMeters: distanceMeters,
            incline: incline,
            avgHeartRate: avgHeartRate,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CardioSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({workoutId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (workoutId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.workoutId,
                    referencedTable:
                        $$CardioSessionsTableReferences._workoutIdTable(db),
                    referencedColumn:
                        $$CardioSessionsTableReferences._workoutIdTable(db).id,
                  ) as T;
                }
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$CardioSessionsTableReferences._exerciseIdTable(db),
                    referencedColumn:
                        $$CardioSessionsTableReferences._exerciseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CardioSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CardioSessionsTable,
    CardioSession,
    $$CardioSessionsTableFilterComposer,
    $$CardioSessionsTableOrderingComposer,
    $$CardioSessionsTableAnnotationComposer,
    $$CardioSessionsTableCreateCompanionBuilder,
    $$CardioSessionsTableUpdateCompanionBuilder,
    (CardioSession, $$CardioSessionsTableReferences),
    CardioSession,
    PrefetchHooks Function({bool workoutId, bool exerciseId})>;
typedef $$PersonalRecordsTableCreateCompanionBuilder = PersonalRecordsCompanion
    Function({
  required String id,
  required String exerciseId,
  required String recordType,
  required double value,
  required int achievedAt,
  Value<String?> workoutSetId,
  Value<int> rowid,
});
typedef $$PersonalRecordsTableUpdateCompanionBuilder = PersonalRecordsCompanion
    Function({
  Value<String> id,
  Value<String> exerciseId,
  Value<String> recordType,
  Value<double> value,
  Value<int> achievedAt,
  Value<String?> workoutSetId,
  Value<int> rowid,
});

final class $$PersonalRecordsTableReferences extends BaseReferences<
    _$AppDatabase, $PersonalRecordsTable, PersonalRecord> {
  $$PersonalRecordsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
          $_aliasNameGenerator(db.personalRecords.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WorkoutSetsTable _workoutSetIdTable(_$AppDatabase db) =>
      db.workoutSets.createAlias($_aliasNameGenerator(
          db.personalRecords.workoutSetId, db.workoutSets.id));

  $$WorkoutSetsTableProcessedTableManager? get workoutSetId {
    final $_column = $_itemColumn<String>('workout_set_id');
    if ($_column == null) return null;
    final manager = $$WorkoutSetsTableTableManager($_db, $_db.workoutSets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutSetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PersonalRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonalRecordsTable> {
  $$PersonalRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordType => $composableBuilder(
      column: $table.recordType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get achievedAt => $composableBuilder(
      column: $table.achievedAt, builder: (column) => ColumnFilters(column));

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WorkoutSetsTableFilterComposer get workoutSetId {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutSetId,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PersonalRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonalRecordsTable> {
  $$PersonalRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordType => $composableBuilder(
      column: $table.recordType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get achievedAt => $composableBuilder(
      column: $table.achievedAt, builder: (column) => ColumnOrderings(column));

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WorkoutSetsTableOrderingComposer get workoutSetId {
    final $$WorkoutSetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutSetId,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableOrderingComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PersonalRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonalRecordsTable> {
  $$PersonalRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recordType => $composableBuilder(
      column: $table.recordType, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get achievedAt => $composableBuilder(
      column: $table.achievedAt, builder: (column) => column);

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WorkoutSetsTableAnnotationComposer get workoutSetId {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutSetId,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PersonalRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PersonalRecordsTable,
    PersonalRecord,
    $$PersonalRecordsTableFilterComposer,
    $$PersonalRecordsTableOrderingComposer,
    $$PersonalRecordsTableAnnotationComposer,
    $$PersonalRecordsTableCreateCompanionBuilder,
    $$PersonalRecordsTableUpdateCompanionBuilder,
    (PersonalRecord, $$PersonalRecordsTableReferences),
    PersonalRecord,
    PrefetchHooks Function({bool exerciseId, bool workoutSetId})> {
  $$PersonalRecordsTableTableManager(
      _$AppDatabase db, $PersonalRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonalRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonalRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> exerciseId = const Value.absent(),
            Value<String> recordType = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<int> achievedAt = const Value.absent(),
            Value<String?> workoutSetId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PersonalRecordsCompanion(
            id: id,
            exerciseId: exerciseId,
            recordType: recordType,
            value: value,
            achievedAt: achievedAt,
            workoutSetId: workoutSetId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String exerciseId,
            required String recordType,
            required double value,
            required int achievedAt,
            Value<String?> workoutSetId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PersonalRecordsCompanion.insert(
            id: id,
            exerciseId: exerciseId,
            recordType: recordType,
            value: value,
            achievedAt: achievedAt,
            workoutSetId: workoutSetId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PersonalRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({exerciseId = false, workoutSetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$PersonalRecordsTableReferences._exerciseIdTable(db),
                    referencedColumn: $$PersonalRecordsTableReferences
                        ._exerciseIdTable(db)
                        .id,
                  ) as T;
                }
                if (workoutSetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.workoutSetId,
                    referencedTable:
                        $$PersonalRecordsTableReferences._workoutSetIdTable(db),
                    referencedColumn: $$PersonalRecordsTableReferences
                        ._workoutSetIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PersonalRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PersonalRecordsTable,
    PersonalRecord,
    $$PersonalRecordsTableFilterComposer,
    $$PersonalRecordsTableOrderingComposer,
    $$PersonalRecordsTableAnnotationComposer,
    $$PersonalRecordsTableCreateCompanionBuilder,
    $$PersonalRecordsTableUpdateCompanionBuilder,
    (PersonalRecord, $$PersonalRecordsTableReferences),
    PersonalRecord,
    PrefetchHooks Function({bool exerciseId, bool workoutSetId})>;
typedef $$WorkoutTemplatesTableCreateCompanionBuilder
    = WorkoutTemplatesCompanion Function({
  required String id,
  required String name,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$WorkoutTemplatesTableUpdateCompanionBuilder
    = WorkoutTemplatesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$WorkoutTemplatesTableReferences extends BaseReferences<
    _$AppDatabase, $WorkoutTemplatesTable, WorkoutTemplate> {
  $$WorkoutTemplatesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TemplateExercisesTable, List<TemplateExercise>>
      _templateExercisesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.templateExercises,
              aliasName: $_aliasNameGenerator(
                  db.workoutTemplates.id, db.templateExercises.templateId));

  $$TemplateExercisesTableProcessedTableManager get templateExercisesRefs {
    final manager = $$TemplateExercisesTableTableManager(
            $_db, $_db.templateExercises)
        .filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_templateExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> templateExercisesRefs(
      Expression<bool> Function($$TemplateExercisesTableFilterComposer f) f) {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.templateExercises,
        getReferencedColumn: (t) => t.templateId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TemplateExercisesTableFilterComposer(
              $db: $db,
              $table: $db.templateExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> templateExercisesRefs<T extends Object>(
      Expression<T> Function($$TemplateExercisesTableAnnotationComposer a) f) {
    final $$TemplateExercisesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.templateExercises,
            getReferencedColumn: (t) => t.templateId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TemplateExercisesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.templateExercises,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$WorkoutTemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutTemplatesTable,
    WorkoutTemplate,
    $$WorkoutTemplatesTableFilterComposer,
    $$WorkoutTemplatesTableOrderingComposer,
    $$WorkoutTemplatesTableAnnotationComposer,
    $$WorkoutTemplatesTableCreateCompanionBuilder,
    $$WorkoutTemplatesTableUpdateCompanionBuilder,
    (WorkoutTemplate, $$WorkoutTemplatesTableReferences),
    WorkoutTemplate,
    PrefetchHooks Function({bool templateExercisesRefs})> {
  $$WorkoutTemplatesTableTableManager(
      _$AppDatabase db, $WorkoutTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutTemplatesCompanion(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutTemplatesCompanion.insert(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutTemplatesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({templateExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (templateExercisesRefs) db.templateExercises
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (templateExercisesRefs)
                    await $_getPrefetchedData<WorkoutTemplate,
                            $WorkoutTemplatesTable, TemplateExercise>(
                        currentTable: table,
                        referencedTable: $$WorkoutTemplatesTableReferences
                            ._templateExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutTemplatesTableReferences(db, table, p0)
                                .templateExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.templateId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutTemplatesTable,
    WorkoutTemplate,
    $$WorkoutTemplatesTableFilterComposer,
    $$WorkoutTemplatesTableOrderingComposer,
    $$WorkoutTemplatesTableAnnotationComposer,
    $$WorkoutTemplatesTableCreateCompanionBuilder,
    $$WorkoutTemplatesTableUpdateCompanionBuilder,
    (WorkoutTemplate, $$WorkoutTemplatesTableReferences),
    WorkoutTemplate,
    PrefetchHooks Function({bool templateExercisesRefs})>;
typedef $$TemplateExercisesTableCreateCompanionBuilder
    = TemplateExercisesCompanion Function({
  required String id,
  required String templateId,
  required String exerciseId,
  required String exerciseName,
  required int targetSets,
  required int targetReps,
  required int orderIndex,
  Value<int> rowid,
});
typedef $$TemplateExercisesTableUpdateCompanionBuilder
    = TemplateExercisesCompanion Function({
  Value<String> id,
  Value<String> templateId,
  Value<String> exerciseId,
  Value<String> exerciseName,
  Value<int> targetSets,
  Value<int> targetReps,
  Value<int> orderIndex,
  Value<int> rowid,
});

final class $$TemplateExercisesTableReferences extends BaseReferences<
    _$AppDatabase, $TemplateExercisesTable, TemplateExercise> {
  $$TemplateExercisesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutTemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.workoutTemplates.createAlias($_aliasNameGenerator(
          db.templateExercises.templateId, db.workoutTemplates.id));

  $$WorkoutTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager =
        $$WorkoutTemplatesTableTableManager($_db, $_db.workoutTemplates)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias($_aliasNameGenerator(
          db.templateExercises.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TemplateExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseName => $composableBuilder(
      column: $table.exerciseName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetSets => $composableBuilder(
      column: $table.targetSets, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetReps => $composableBuilder(
      column: $table.targetReps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  $$WorkoutTemplatesTableFilterComposer get templateId {
    final $$WorkoutTemplatesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.templateId,
        referencedTable: $db.workoutTemplates,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutTemplatesTableFilterComposer(
              $db: $db,
              $table: $db.workoutTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TemplateExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseName => $composableBuilder(
      column: $table.exerciseName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetSets => $composableBuilder(
      column: $table.targetSets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetReps => $composableBuilder(
      column: $table.targetReps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  $$WorkoutTemplatesTableOrderingComposer get templateId {
    final $$WorkoutTemplatesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.templateId,
        referencedTable: $db.workoutTemplates,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutTemplatesTableOrderingComposer(
              $db: $db,
              $table: $db.workoutTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TemplateExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseName => $composableBuilder(
      column: $table.exerciseName, builder: (column) => column);

  GeneratedColumn<int> get targetSets => $composableBuilder(
      column: $table.targetSets, builder: (column) => column);

  GeneratedColumn<int> get targetReps => $composableBuilder(
      column: $table.targetReps, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  $$WorkoutTemplatesTableAnnotationComposer get templateId {
    final $$WorkoutTemplatesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.templateId,
        referencedTable: $db.workoutTemplates,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutTemplatesTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TemplateExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TemplateExercisesTable,
    TemplateExercise,
    $$TemplateExercisesTableFilterComposer,
    $$TemplateExercisesTableOrderingComposer,
    $$TemplateExercisesTableAnnotationComposer,
    $$TemplateExercisesTableCreateCompanionBuilder,
    $$TemplateExercisesTableUpdateCompanionBuilder,
    (TemplateExercise, $$TemplateExercisesTableReferences),
    TemplateExercise,
    PrefetchHooks Function({bool templateId, bool exerciseId})> {
  $$TemplateExercisesTableTableManager(
      _$AppDatabase db, $TemplateExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateExercisesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> templateId = const Value.absent(),
            Value<String> exerciseId = const Value.absent(),
            Value<String> exerciseName = const Value.absent(),
            Value<int> targetSets = const Value.absent(),
            Value<int> targetReps = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TemplateExercisesCompanion(
            id: id,
            templateId: templateId,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            targetSets: targetSets,
            targetReps: targetReps,
            orderIndex: orderIndex,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String templateId,
            required String exerciseId,
            required String exerciseName,
            required int targetSets,
            required int targetReps,
            required int orderIndex,
            Value<int> rowid = const Value.absent(),
          }) =>
              TemplateExercisesCompanion.insert(
            id: id,
            templateId: templateId,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            targetSets: targetSets,
            targetReps: targetReps,
            orderIndex: orderIndex,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TemplateExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({templateId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (templateId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.templateId,
                    referencedTable:
                        $$TemplateExercisesTableReferences._templateIdTable(db),
                    referencedColumn: $$TemplateExercisesTableReferences
                        ._templateIdTable(db)
                        .id,
                  ) as T;
                }
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$TemplateExercisesTableReferences._exerciseIdTable(db),
                    referencedColumn: $$TemplateExercisesTableReferences
                        ._exerciseIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TemplateExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TemplateExercisesTable,
    TemplateExercise,
    $$TemplateExercisesTableFilterComposer,
    $$TemplateExercisesTableOrderingComposer,
    $$TemplateExercisesTableAnnotationComposer,
    $$TemplateExercisesTableCreateCompanionBuilder,
    $$TemplateExercisesTableUpdateCompanionBuilder,
    (TemplateExercise, $$TemplateExercisesTableReferences),
    TemplateExercise,
    PrefetchHooks Function({bool templateId, bool exerciseId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BodyMetricsTableTableManager get bodyMetrics =>
      $$BodyMetricsTableTableManager(_db, _db.bodyMetrics);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db, _db.workoutSets);
  $$CardioSessionsTableTableManager get cardioSessions =>
      $$CardioSessionsTableTableManager(_db, _db.cardioSessions);
  $$PersonalRecordsTableTableManager get personalRecords =>
      $$PersonalRecordsTableTableManager(_db, _db.personalRecords);
  $$WorkoutTemplatesTableTableManager get workoutTemplates =>
      $$WorkoutTemplatesTableTableManager(_db, _db.workoutTemplates);
  $$TemplateExercisesTableTableManager get templateExercises =>
      $$TemplateExercisesTableTableManager(_db, _db.templateExercises);
}
