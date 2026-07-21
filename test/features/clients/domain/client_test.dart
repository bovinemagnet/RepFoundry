import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';

void main() {
  test('create sets a non-empty id and the given fields', () {
    final c = Client.create(name: 'Sarah', colour: 0xFF2196F3, notes: 'knee');
    expect(c.id, isNotEmpty);
    expect(c.name, 'Sarah');
    expect(c.colour, 0xFF2196F3);
    expect(c.notes, 'knee');
    expect(c.isSelf, isFalse);
  });

  test('copyWith replaces only named fields', () {
    final c = Client.create(name: 'Sarah', colour: 0xFF000000);
    final renamed = c.copyWith(name: 'Sarah J');
    expect(renamed.name, 'Sarah J');
    expect(renamed.id, c.id);
    expect(renamed.colour, c.colour);
  });

  test('self client id constant is stable', () {
    expect(kSelfClientId, '00000000-0000-4000-8000-000000000001');
  });
}
