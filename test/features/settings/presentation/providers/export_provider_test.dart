import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/settings/application/export_data_use_case.dart';
import 'package:rep_foundry/features/settings/presentation/providers/export_provider.dart';

class _MockExportDataUseCase extends Mock implements ExportDataUseCase {
  @override
  Future<String> exportAsJson() => super.noSuchMethod(
        Invocation.method(#exportAsJson, []),
        returnValue: Future<String>.value(''),
        returnValueForMissingStub: Future<String>.value(''),
      );

  @override
  Future<Map<String, String>> exportAsCsv() => super.noSuchMethod(
        Invocation.method(#exportAsCsv, []),
        returnValue: Future<Map<String, String>>.value(<String, String>{}),
        returnValueForMissingStub:
            Future<Map<String, String>>.value(<String, String>{}),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportState', () {
    test('default constructor is idle with no error or path', () {
      const state = ExportState();
      expect(state.status, ExportStatus.idle);
      expect(state.error, isNull);
      expect(state.savedPath, isNull);
    });

    test('explicit construction stores provided fields', () {
      const state = ExportState(
        status: ExportStatus.completed,
        savedPath: '/tmp/exports',
      );
      expect(state.status, ExportStatus.completed);
      expect(state.savedPath, '/tmp/exports');
      expect(state.error, isNull);
    });
  });

  group('ExportNotifier', () {
    test('initial state is idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(exportProvider);
      expect(state.status, ExportStatus.idle);
      expect(state.error, isNull);
      expect(state.savedPath, isNull);
    });

    test('reset returns the notifier to the idle state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(exportProvider.notifier);
      notifier.reset();

      expect(container.read(exportProvider).status, ExportStatus.idle);
    });

    test('exportJson failure path puts state into failed with error message',
        () async {
      final mock = _MockExportDataUseCase();
      when(mock.exportAsJson()).thenThrow(Exception('export-broken'));

      final container = ProviderContainer(
        overrides: [
          exportDataUseCaseProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      await container.read(exportProvider.notifier).exportJson();

      final state = container.read(exportProvider);
      expect(state.status, ExportStatus.failed);
      expect(state.error, contains('export-broken'));
    });

    test('exportCsv failure path puts state into failed with error message',
        () async {
      final mock = _MockExportDataUseCase();
      when(mock.exportAsCsv()).thenThrow(Exception('csv-broken'));

      final container = ProviderContainer(
        overrides: [
          exportDataUseCaseProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      await container.read(exportProvider.notifier).exportCsv();

      final state = container.read(exportProvider);
      expect(state.status, ExportStatus.failed);
      expect(state.error, contains('csv-broken'));
    });

    test('reset after failure clears error', () async {
      final mock = _MockExportDataUseCase();
      when(mock.exportAsJson()).thenThrow(Exception('boom'));

      final container = ProviderContainer(
        overrides: [
          exportDataUseCaseProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      await container.read(exportProvider.notifier).exportJson();
      expect(container.read(exportProvider).status, ExportStatus.failed);

      container.read(exportProvider.notifier).reset();
      expect(container.read(exportProvider).status, ExportStatus.idle);
      expect(container.read(exportProvider).error, isNull);
    });
  });
}
