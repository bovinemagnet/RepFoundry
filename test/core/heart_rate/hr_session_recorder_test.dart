import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/heart_rate/hr_session_recorder.dart';
import 'package:rep_foundry/core/providers.dart';

import '../../features/cardio/data/fake_heart_rate_service.dart';

void main() {
  group('summariseSamples', () {
    final base = DateTime.utc(2026, 7, 18, 10, 0, 0);

    HrSample sample(int bpm, int secondsAfterBase) => HrSample(
        bpm: bpm, timestamp: base.add(Duration(seconds: secondsAfterBase)));

    test('returns null when there are no samples in the window', () {
      final samples = [sample(120, 0), sample(130, 300)];
      final summary = summariseSamples(
        samples,
        from: base.add(const Duration(seconds: 60)),
        to: base.add(const Duration(seconds: 120)),
      );
      expect(summary, isNull);
    });

    test('returns null for an empty sample list', () {
      final summary = summariseSamples(
        const [],
        from: base,
        to: base.add(const Duration(minutes: 5)),
      );
      expect(summary, isNull);
    });

    test('computes average and peak over samples inside the window', () {
      final samples = [
        sample(100, 0), // at `from` — excluded (belongs to previous window)
        sample(120, 10),
        sample(140, 20),
        sample(160, 30), // at `to` — included
        sample(180, 40), // after `to` — excluded
      ];
      final summary = summariseSamples(
        samples,
        from: base,
        to: base.add(const Duration(seconds: 30)),
      );
      expect(summary, isNotNull);
      expect(summary!.avgBpm, 140);
      expect(summary.peakBpm, 160);
    });

    test('rounds the average to the nearest whole bpm', () {
      final samples = [sample(100, 10), sample(101, 20)];
      final summary = summariseSamples(
        samples,
        from: base,
        to: base.add(const Duration(minutes: 1)),
      )!;
      expect(summary.avgBpm, 101); // 100.5 rounds up
      expect(summary.peakBpm, 101);
    });
  });

  group('HrSessionRecorder', () {
    late FakeHeartRateService service;
    late ProviderContainer container;

    setUp(() {
      service = FakeHeartRateService();
      container = ProviderContainer(overrides: [
        heartRateServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);
      addTearDown(service.dispose);
    });

    test('buffers timestamped samples from the heart rate stream', () async {
      final recorder = container.read(hrSessionRecorderProvider.notifier);
      final before = DateTime.now().toUtc();

      service.emitHeartRate(120);
      service.emitHeartRate(135);
      await Future<void>.delayed(Duration.zero);

      final after = DateTime.now().toUtc();
      final samples = container.read(hrSessionRecorderProvider);
      expect(samples, hasLength(2));
      expect(samples.map((s) => s.bpm), [120, 135]);
      for (final s in samples) {
        expect(
          s.timestamp.isBefore(before) || s.timestamp.isAfter(after),
          isFalse,
        );
      }

      final summary = recorder.summarise(
        from: before.subtract(const Duration(seconds: 1)),
        to: after.add(const Duration(seconds: 1)),
      );
      expect(summary!.avgBpm, 128);
      expect(summary.peakBpm, 135);
    });

    test('drops non-positive readings', () async {
      container.read(hrSessionRecorderProvider.notifier);

      service.emitHeartRate(0);
      service.emitHeartRate(-3);
      service.emitHeartRate(90);
      await Future<void>.delayed(Duration.zero);

      final samples = container.read(hrSessionRecorderProvider);
      expect(samples.map((s) => s.bpm), [90]);
    });

    test('clear() empties the buffer', () async {
      final recorder = container.read(hrSessionRecorderProvider.notifier);

      service.emitHeartRate(110);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(hrSessionRecorderProvider), isNotEmpty);

      recorder.clear();
      expect(container.read(hrSessionRecorderProvider), isEmpty);
    });
  });
}
