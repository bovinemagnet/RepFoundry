import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/mcp/domain/mcp_host_support.dart';

void main() {
  group('isMcpHostSupported', () {
    test('is true on each desktop platform', () {
      expect(isMcpHostSupported(isMacOS: true), isTrue);
      expect(isMcpHostSupported(isWindows: true), isTrue);
      expect(isMcpHostSupported(isLinux: true), isTrue);
    });

    test('is false on iOS and Android, where every desktop flag is false', () {
      expect(isMcpHostSupported(), isFalse);
    });

    test('is false on web, even if a desktop flag is set', () {
      expect(isMcpHostSupported(isWeb: true), isFalse);
      expect(isMcpHostSupported(isWeb: true, isMacOS: true), isFalse);
    });
  });
}
