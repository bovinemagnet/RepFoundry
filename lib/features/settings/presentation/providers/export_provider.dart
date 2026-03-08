import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers.dart';

enum ExportStatus { idle, exporting, completed, failed }

class ExportState {
  final ExportStatus status;
  final String? error;

  const ExportState({this.status = ExportStatus.idle, this.error});
}

class ExportNotifier extends StateNotifier<ExportState> {
  final Ref _ref;

  ExportNotifier(this._ref) : super(const ExportState());

  Future<void> exportJson() async {
    state = const ExportState(status: ExportStatus.exporting);
    try {
      final useCase = _ref.read(exportDataUseCaseProvider);
      final json = await useCase.exportAsJson();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/repfoundry_export.json');
      await file.writeAsString(json);

      await Share.shareXFiles([XFile(file.path)]);
      state = const ExportState(status: ExportStatus.completed);
    } catch (e) {
      state = ExportState(status: ExportStatus.failed, error: e.toString());
    }
  }

  Future<void> exportCsv() async {
    state = const ExportState(status: ExportStatus.exporting);
    try {
      final useCase = _ref.read(exportDataUseCaseProvider);
      final csvFiles = await useCase.exportAsCsv();

      final dir = await getTemporaryDirectory();
      final files = <XFile>[];
      for (final entry in csvFiles.entries) {
        final file = File('${dir.path}/${entry.key}');
        await file.writeAsString(entry.value);
        files.add(XFile(file.path));
      }

      await Share.shareXFiles(files);
      state = const ExportState(status: ExportStatus.completed);
    } catch (e) {
      state = ExportState(status: ExportStatus.failed, error: e.toString());
    }
  }

  void reset() {
    state = const ExportState();
  }
}

final exportProvider =
    StateNotifierProvider<ExportNotifier, ExportState>((ref) {
  return ExportNotifier(ref);
});
