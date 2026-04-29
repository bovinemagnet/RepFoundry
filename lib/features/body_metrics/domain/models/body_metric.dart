import 'package:uuid/uuid.dart';

class BodyMetric {
  final String id;
  final DateTime date;
  final double weight;
  final double? bodyFatPercent;
  final String? notes;
  final DateTime updatedAt;

  const BodyMetric({
    required this.id,
    required this.date,
    required this.weight,
    this.bodyFatPercent,
    this.notes,
    required this.updatedAt,
  });

  BodyMetric copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? bodyFatPercent,
    String? notes,
    bool clearBodyFat = false,
    bool clearNotes = false,
    DateTime? updatedAt,
  }) {
    return BodyMetric(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bodyFatPercent:
          clearBodyFat ? null : (bodyFatPercent ?? this.bodyFatPercent),
      notes: clearNotes ? null : (notes ?? this.notes),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static BodyMetric create({
    required double weight,
    DateTime? date,
    double? bodyFatPercent,
    String? notes,
  }) {
    final now = DateTime.now().toUtc();
    return BodyMetric(
      id: const Uuid().v4(),
      date: date ?? now,
      weight: weight,
      bodyFatPercent: bodyFatPercent,
      notes: notes,
      updatedAt: now,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMetric && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BodyMetric(id: $id, date: $date, weight: $weight)';
}
