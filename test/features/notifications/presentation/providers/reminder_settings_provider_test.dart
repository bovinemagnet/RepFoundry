import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/notifications/presentation/providers/reminder_settings_provider.dart';

void main() {
  group('ReminderSettings serialisation', () {
    test('daysToString and stringToDays roundtrip', () {
      final days = {DateTime.monday, DateTime.wednesday, DateTime.friday};
      final encoded = daysToString(days);
      final decoded = stringToDays(encoded);
      expect(decoded, days);
    });

    test('empty days produce empty string', () {
      expect(daysToString({}), '');
      expect(stringToDays(''), isEmpty);
    });
  });
}
