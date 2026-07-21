import 'package:uuid/uuid.dart';

import '../../../clients/domain/models/client.dart';

class BodyMetric {
  final String id;
  final DateTime date;
  final double weight;
  final double? bodyFatPercent;
  final String? notes;
  final String clientId;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const BodyMetric({
    required this.id,
    required this.date,
    required this.weight,
    this.bodyFatPercent,
    this.notes,
    required this.clientId,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  BodyMetric copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? bodyFatPercent,
    String? notes,
    bool clearBodyFat = false,
    bool clearNotes = false,
    String? clientId,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return BodyMetric(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bodyFatPercent:
          clearBodyFat ? null : (bodyFatPercent ?? this.bodyFatPercent),
      notes: clearNotes ? null : (notes ?? this.notes),
      clientId: clientId ?? this.clientId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static BodyMetric create({
    required double weight,
    DateTime? date,
    double? bodyFatPercent,
    String? notes,
    String clientId = kSelfClientId,
  }) {
    final now = DateTime.now().toUtc();
    return BodyMetric(
      id: const Uuid().v4(),
      date: date ?? now,
      weight: weight,
      bodyFatPercent: bodyFatPercent,
      notes: notes,
      clientId: clientId,
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
