import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// A single heart-rate reading with the absolute time it arrived, so it can
/// be correlated with other absolutely-timestamped events (e.g. logged sets).
class HrSample {
  final int bpm;
  final DateTime timestamp;

  const HrSample({required this.bpm, required this.timestamp});
}

/// Average and peak BPM over a time window.
class HrWindowSummary {
  final int avgBpm;
  final int peakBpm;

  const HrWindowSummary({required this.avgBpm, required this.peakBpm});
}

/// Summarises the samples that fall inside `(from, to]`.
///
/// `from` is exclusive so a sample stamped exactly at the previous window's
/// end is not counted twice. Returns null when the window holds no samples.
HrWindowSummary? summariseSamples(
  List<HrSample> samples, {
  required DateTime from,
  required DateTime to,
}) {
  final inWindow = samples
      .where((s) => s.timestamp.isAfter(from) && !s.timestamp.isAfter(to))
      .toList();
  if (inWindow.isEmpty) return null;

  var sum = 0;
  var peak = 0;
  for (final s in inWindow) {
    sum += s.bpm;
    if (s.bpm > peak) peak = s.bpm;
  }
  return HrWindowSummary(
    avgBpm: (sum / inWindow.length).round(),
    peakBpm: peak,
  );
}

/// Buffers timestamped heart-rate samples from the shared [HeartRateService]
/// for as long as a monitor is connected, regardless of which screen started
/// the connection. Consumers ask for a window summary via [summarise].
class HrSessionRecorder extends Notifier<List<HrSample>> {
  StreamSubscription<int>? _subscription;

  /// Samples older than this are pruned as new ones arrive, keeping the
  /// buffer bounded across very long sessions.
  static const _retention = Duration(hours: 6);

  @override
  List<HrSample> build() {
    final service = ref.watch(heartRateServiceProvider);
    _subscription?.cancel();
    _subscription = service.heartRateStream.listen(_onReading);
    ref.onDispose(() => _subscription?.cancel());
    return const [];
  }

  void _onReading(int bpm) {
    if (bpm <= 0) return;
    final now = DateTime.now().toUtc();
    final cutoff = now.subtract(_retention);
    state = [
      ...state.where((s) => s.timestamp.isAfter(cutoff)),
      HrSample(bpm: bpm, timestamp: now),
    ];
  }

  HrWindowSummary? summarise({required DateTime from, required DateTime to}) {
    return summariseSamples(state, from: from, to: to);
  }

  void clear() {
    state = const [];
  }
}

final hrSessionRecorderProvider =
    NotifierProvider<HrSessionRecorder, List<HrSample>>(HrSessionRecorder.new);
