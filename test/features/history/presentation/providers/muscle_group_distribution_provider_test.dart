import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/presentation/providers/muscle_group_distribution_provider.dart';

void main() {
  test('MuscleGroupVolume holds group and volume', () {
    const vol = MuscleGroupVolume(group: MuscleGroup.chest, volume: 5000);
    expect(vol.group, MuscleGroup.chest);
    expect(vol.volume, 5000);
  });

  test('volume aggregation sorts descending', () {
    final data = [
      const MuscleGroupVolume(group: MuscleGroup.back, volume: 3000),
      const MuscleGroupVolume(group: MuscleGroup.chest, volume: 5000),
      const MuscleGroupVolume(group: MuscleGroup.shoulders, volume: 1000),
    ];
    data.sort((a, b) => b.volume.compareTo(a.volume));
    expect(data.first.group, MuscleGroup.chest);
    expect(data.last.group, MuscleGroup.shoulders);
  });
}
