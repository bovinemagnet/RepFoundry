import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/mcp/application/mcp_args.dart';
import 'package:rep_foundry/features/mcp/application/mcp_tool.dart';

final _toolError = throwsA(isA<McpToolError>());

void main() {
  group('parseLimit', () {
    test('defaults to 20 when absent', () => expect(parseLimit({}), 20));
    test('clamps 0 up to 1', () => expect(parseLimit({'limit': 0}), 1));
    test('clamps 500 down to 100',
        () => expect(parseLimit({'limit': 500}), 100));
    test('accepts an integral double',
        () => expect(parseLimit({'limit': 12.0}), 12));
    test('rejects a string',
        () => expect(() => parseLimit({'limit': 'ten'}), _toolError));
    test('rejects a fractional number',
        () => expect(() => parseLimit({'limit': 2.5}), _toolError));
    test('honours a custom default and maximum', () {
      expect(parseLimit({}, defaultValue: 8, max: 52), 8);
      expect(parseLimit({'limit': 99}, max: 52), 52);
    });
  });

  group('parseDate', () {
    test('is null when absent', () => expect(parseDate({}, 'from'), isNull));
    test('reads a date as local midnight', () {
      expect(parseDate({'from': '2026-11-01'}, 'from'), DateTime(2026, 11, 1));
    });
    test('reads a date-time with an offset', () {
      expect(parseDate({'to': '2026-11-01T10:00:00Z'}, 'to'),
          DateTime.utc(2026, 11, 1, 10));
    });
    test(
        'rejects free text',
        () =>
            expect(() => parseDate({'from': 'yesterday'}, 'from'), _toolError));
    test('rejects a number',
        () => expect(() => parseDate({'from': 20261101}, 'from'), _toolError));
  });

  group('cursor', () {
    test('round-trips an instant', () {
      final t = DateTime.utc(2026, 3, 4, 5, 6, 7, 8);
      expect(decodeCursor({'cursor': encodeCursor(t)}), t);
    });
    test('is null when absent', () => expect(decodeCursor({}), isNull));
    test('rejects a forged value',
        () => expect(() => decodeCursor({'cursor': '!!'}), _toolError));
    test('rejects base64 that is not a timestamp', () {
      expect(() => decodeCursor({'cursor': 'aGVsbG8'}), _toolError);
    });
  });

  group('strings', () {
    test('requireString returns the value', () {
      expect(requireString({'id': 'abc'}, 'id'), 'abc');
    });
    test('requireString rejects missing, empty and non-string', () {
      expect(() => requireString({}, 'id'), _toolError);
      expect(() => requireString({'id': ''}, 'id'), _toolError);
      expect(() => requireString({'id': 3}, 'id'), _toolError);
    });
    test('optionalString is null when absent and rejects non-string', () {
      expect(optionalString({}, 'q'), isNull);
      expect(() => optionalString({'q': 1}, 'q'), _toolError);
    });
  });

  group('isoLocal', () {
    test('carries an explicit offset and parses back to the same instant', () {
      final t = DateTime.utc(2026, 7, 1, 23, 30);
      final s = isoLocal(t);
      expect(
          s,
          matches(RegExp(
              r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d{3})?[+-]\d\d:\d\d$')));
      expect(DateTime.parse(s).isAtSameMomentAs(t), isTrue);
    });
    test('isoLocalOrNull passes null through',
        () => expect(isoLocalOrNull(null), isNull));
  });

  test('round2 rounds to two decimals', () {
    expect(round2(1.23456), 1.23);
    expect(round2(2.005 + 0.0001), 2.01);
  });

  test('objectSchema builds an object schema', () {
    final s = objectSchema({
      'a': {'type': 'string'}
    }, required: [
      'a'
    ]);
    expect(s['type'], 'object');
    expect(s['properties'], {
      'a': {'type': 'string'}
    });
    expect(s['required'], ['a']);
    expect(objectSchema({}).containsKey('required'), isFalse);
  });
}
