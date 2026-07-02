import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';
import 'package:rep_foundry/core/units/weight_unit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initial synchronous state is kg', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(weightUnitProvider), WeightUnit.kg);
  });

  test('loads a persisted lbs choice', () async {
    SharedPreferences.setMockInitialValues({'weight_unit': 'lbs'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(weightUnitProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(weightUnitProvider), WeightUnit.lbs);
  });

  test('set() updates state and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(weightUnitProvider.notifier).set(WeightUnit.lbs);
    expect(container.read(weightUnitProvider), WeightUnit.lbs);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('weight_unit'), 'lbs');
  });

  test('a persisted choice is never overridden by locale default', () async {
    SharedPreferences.setMockInitialValues({'weight_unit': 'kg'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(weightUnitProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(weightUnitProvider), WeightUnit.kg);
  });
}
