import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/notifications/data/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  group('nextInstanceOfTime', () {
    test('returns a TZDateTime in the configured local zone', () {
      tz.setLocalLocation(tz.getLocation('Australia/Sydney'));
      final result = nextInstanceOfTime(18, 0);
      expect(result.location.name, 'Australia/Sydney');
      expect(result.hour, 18);
      expect(result.minute, 0);
    });

    test('Sydney instance has a non-UTC offset (proves tz.local was set)', () {
      tz.setLocalLocation(tz.getLocation('Australia/Sydney'));
      final result = nextInstanceOfTime(12, 0);
      // Sydney is UTC+10 or UTC+11 depending on DST — never zero.
      expect(result.timeZoneOffset, isNot(Duration.zero));
    });

    test('time before now today rolls to tomorrow', () {
      tz.setLocalLocation(tz.getLocation('UTC'));
      final now = tz.TZDateTime.now(tz.local);
      final pastHour = (now.hour - 2 + 24) % 24;
      final result = nextInstanceOfTime(pastHour, 0);
      expect(result.isAfter(now), isTrue);
    });
  });

  group('nextInstanceOfDayAndTime', () {
    test('lands on the requested weekday in the local zone', () {
      tz.setLocalLocation(tz.getLocation('Australia/Sydney'));
      final result = nextInstanceOfDayAndTime(DateTime.wednesday, 9, 30);
      expect(result.weekday, DateTime.wednesday);
      expect(result.hour, 9);
      expect(result.minute, 30);
      expect(result.location.name, 'Australia/Sydney');
    });

    test('past instance today rolls forward by 7 days', () {
      tz.setLocalLocation(tz.getLocation('UTC'));
      final now = tz.TZDateTime.now(tz.local);
      final result = nextInstanceOfDayAndTime(now.weekday, 0, 0);
      expect(result.isAfter(now), isTrue);
    });
  });
}
