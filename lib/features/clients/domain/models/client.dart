import 'package:uuid/uuid.dart';

/// Fixed id of the always-present "Me" client. The coach's own training data
/// lives here, and every pre-coach-mode row migrates into it.
const String kSelfClientId = '00000000-0000-4000-8000-000000000001';

/// A person the coach trains. Coach-owned; clients never log in.
class Client {
  const Client({
    required this.id,
    required this.name,
    required this.colour,
    required this.notes,
    required this.isSelf,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;
  final String name;

  /// ARGB accent colour used on the roster and switcher.
  final int colour;
  final String? notes;

  /// True for the single undeletable "Me" client.
  final bool isSelf;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory Client.create({
    required String name,
    required int colour,
    String? notes,
  }) {
    final now = DateTime.now().toUtc();
    return Client(
      id: const Uuid().v4(),
      name: name,
      colour: colour,
      notes: notes,
      isSelf: false,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    );
  }

  Client copyWith({
    String? name,
    int? colour,
    String? notes,
    bool clearNotes = false,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      colour: colour ?? this.colour,
      notes: clearNotes ? null : (notes ?? this.notes),
      isSelf: isSelf,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  bool operator ==(Object other) => other is Client && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
