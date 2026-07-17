import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/data/reconnect_strategy.dart';

void main() {
  group('ReconnectStrategy', () {
    test('default schedule covers at least a four minute window', () {
      final total = ReconnectStrategy.defaultDelays
          .fold(Duration.zero, (sum, d) => sum + d);
      expect(total, greaterThanOrEqualTo(const Duration(minutes: 4)));
    });

    test('returns true after a successful first attempt', () {
      fakeAsync((async) {
        var attempts = 0;
        bool? result;

        const ReconnectStrategy(delays: [Duration(seconds: 2)])
            .run(
              attempt: () async => attempts++,
              isCancelled: () => false,
            )
            .then((r) => result = r);

        async.elapse(const Duration(seconds: 2));
        expect(attempts, 1);
        expect(result, isTrue);
      });
    });

    test('retries after each failure using the backoff delays', () {
      fakeAsync((async) {
        final attemptTimes = <Duration>[];
        var attempts = 0;
        bool? result;

        const ReconnectStrategy(
          delays: [
            Duration(seconds: 2),
            Duration(seconds: 4),
            Duration(seconds: 8),
            Duration(seconds: 16),
          ],
        )
            .run(
              attempt: () async {
                attempts++;
                attemptTimes.add(async.elapsed);
                if (attempts < 4) throw Exception('still out of range');
              },
              isCancelled: () => false,
            )
            .then((r) => result = r);

        async.elapse(const Duration(seconds: 30));
        expect(attempts, 4);
        expect(attemptTimes, const [
          Duration(seconds: 2),
          Duration(seconds: 6),
          Duration(seconds: 14),
          Duration(seconds: 30),
        ]);
        expect(result, isTrue);
      });
    });

    test('returns false once every delay is exhausted', () {
      fakeAsync((async) {
        var attempts = 0;
        bool? result;

        const ReconnectStrategy(
          delays: [Duration(seconds: 2), Duration(seconds: 4)],
        )
            .run(
              attempt: () async {
                attempts++;
                throw Exception('unreachable device');
              },
              isCancelled: () => false,
            )
            .then((r) => result = r);

        async.elapse(const Duration(minutes: 1));
        expect(attempts, 2);
        expect(result, isFalse);
      });
    });

    test('retryOnceOnFailure returns the first success without retrying', () {
      fakeAsync((async) {
        var calls = 0;
        String? result;

        retryOnceOnFailure(() async {
          calls++;
          return 'connected';
        }).then((r) => result = r);

        async.elapse(Duration.zero);
        expect(calls, 1);
        expect(result, 'connected');
      });
    });

    test('retryOnceOnFailure retries once after a transient failure', () {
      fakeAsync((async) {
        var calls = 0;
        String? result;

        retryOnceOnFailure(() async {
          calls++;
          if (calls == 1) throw Exception('GATT 133');
          return 'connected';
        }).then((r) => result = r);

        // The retry waits one second before the second attempt.
        async.elapse(const Duration(milliseconds: 999));
        expect(calls, 1);
        async.elapse(const Duration(milliseconds: 1));
        expect(calls, 2);
        expect(result, 'connected');
      });
    });

    test('retryOnceOnFailure rethrows when the retry also fails', () {
      fakeAsync((async) {
        var calls = 0;
        Object? error;

        retryOnceOnFailure<void>(() async {
          calls++;
          throw Exception('attempt $calls failed');
        }).catchError((Object e) => error = e);

        async.elapse(const Duration(seconds: 2));
        expect(calls, 2);
        expect(error.toString(), contains('attempt 2 failed'));
      });
    });

    test('stops without further attempts when cancelled mid-backoff', () {
      fakeAsync((async) {
        var attempts = 0;
        var cancelled = false;
        bool? result;

        const ReconnectStrategy(
          delays: [Duration(seconds: 2), Duration(seconds: 4)],
        )
            .run(
              attempt: () async {
                attempts++;
                throw Exception('still out of range');
              },
              isCancelled: () => cancelled,
            )
            .then((r) => result = r);

        async.elapse(const Duration(seconds: 3));
        expect(attempts, 1);
        cancelled = true;

        async.elapse(const Duration(minutes: 1));
        expect(attempts, 1);
        expect(result, isFalse);
      });
    });
  });
}
