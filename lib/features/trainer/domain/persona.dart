import 'trainer_event.dart';

/// A named coaching tone: the bank of phrase keys it draws on per event kind.
class Persona {
  const Persona({required this.id, required this.phrasesByKind});

  final String id;

  /// ARB phrase keys, never literal text.
  final Map<TrainerEventKind, List<String>> phrasesByKind;

  List<String> phrasesFor(TrainerEventKind kind) =>
      phrasesByKind[kind] ?? const [];
}
