import 'package:uuid/uuid.dart';

class BodyMetric {
  final String id;
  final DateTime date;
  final double weight;
  final double? bodyFatPercent;
  final String? notes;

  const BodyMetric({
    required this.id,
    required this.date,
    required this.weight,
    this.bodyFatPercent,
    this.notes,
  });

  BodyMetric copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? bodyFatPercent,
    String? notes,
    bool clearBodyFat = false,
    bool clearNotes = false,
  }) {
    return BodyMetric(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bodyFatPercent: clearBodyFat ? null : (bodyFatPercent ?? this.bodyFatPercent),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  static BodyMetric create({
    required double weight,
    DateTime? date,
    double? bodyFatPercent,
    String? notes,
  }) {
    return BodyMetric(
      id: const Uuid().v4(),
      date: date ?? DateTime.now().toUtc(),
      weight: weight,
      bodyFatPercent: bodyFatPercent,
      notes: notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMetric && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BodyMetric(id: $id, date: $date, weight: $weight)';
}
