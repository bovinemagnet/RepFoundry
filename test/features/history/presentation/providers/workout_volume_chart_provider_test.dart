import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/progress_chart_widget.dart';

void main() {
  test('ProgressDataPoint holds date and value', () {
    final point = ProgressDataPoint(
      date: DateTime(2024, 6, 15),
      value: 1500.0,
    );
    expect(point.date, DateTime(2024, 6, 15));
    expect(point.value, 1500.0);
  });

  test('volume computation from sets is correct', () {
    // Simulate per-workout volume calculation
    final setVolumes = [100.0 * 5, 80.0 * 8, 60.0 * 12]; // 500, 640, 720
    final totalVolume = setVolumes.fold<double>(0, (sum, v) => sum + v);
    expect(totalVolume, 1860.0);
  });
}
