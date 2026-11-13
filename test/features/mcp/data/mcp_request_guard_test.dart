import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/mcp/data/mcp_request_guard.dart';

void main() {
  const port = 47600;
  const token = 'secret-token';

  bool allowed({
    String? host = '127.0.0.1:47600',
    String? origin,
    String? authorization = 'Bearer secret-token',
    String configuredToken = token,
  }) =>
      isMcpRequestAllowed(
        host: host,
        origin: origin,
        authorization: authorization,
        port: port,
        token: configuredToken,
      );

  test('allows the exact loopback host and port with the token', () {
    expect(allowed(), isTrue);
    expect(allowed(host: 'localhost:47600'), isTrue);
    expect(allowed(host: 'LOCALHOST:47600'), isTrue);
  });

  test('rejects another port',
      () => expect(allowed(host: 'localhost:47601'), isFalse));

  test('rejects a host with no port',
      () => expect(allowed(host: 'localhost'), isFalse));

  test('rejects a foreign host', () {
    expect(allowed(host: 'evil.example:47600'), isFalse);
    expect(allowed(host: null), isFalse);
  });

  test('rejects any Origin, including a local one', () {
    expect(allowed(origin: 'http://localhost:5173'), isFalse);
    expect(allowed(origin: 'null'), isFalse);
  });

  test('treats a blank Origin as absent',
      () => expect(allowed(origin: '  '), isTrue));

  test('rejects a missing or wrong token', () {
    expect(allowed(authorization: null), isFalse);
    expect(allowed(authorization: 'Bearer wrong-token!'), isFalse);
    expect(allowed(authorization: 'secret-token'), isFalse);
    expect(allowed(authorization: 'Basic secret-token'), isFalse);
  });

  test('rejects everything when no token is configured', () {
    expect(allowed(authorization: 'Bearer ', configuredToken: ''), isFalse);
  });
}
