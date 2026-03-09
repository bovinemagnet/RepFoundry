import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers.dart';

enum ExportStatus { idle, exporting, completed, failed }

class ExportState {
  final ExportStatus status;
  final String? error;
  final String? savedPath;

  const ExportState({
    this.status = ExportStatus.idle,
    this.error,
    this.savedPath,
  });
}

class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState();

  Future<void> exportJson() async {
    state = const ExportState(status: ExportStatus.exporting);
    try {
      final useCase = ref.read(exportDataUseCaseProvider);
      final json = await useCase.exportAsJson();

      final dir = await _exportDirectory();
      final file = File('${dir.path}/repfoundry_export.json');
      await file.writeAsString(json);

      await _shareOrSave([XFile(file.path)], dir.path);
    } catch (e) {
      state = ExportState(status: ExportStatus.failed, error: e.toString());
    }
  }

  Future<void> exportCsv() async {
    state = const ExportState(status: ExportStatus.exporting);
    try {
      final useCase = ref.read(exportDataUseCaseProvider);
      final csvFiles = await useCase.exportAsCsv();

      final dir = await _exportDirectory();
      final files = <XFile>[];
      for (final entry in csvFiles.entries) {
        final file = File('${dir.path}/${entry.key}');
        await file.writeAsString(entry.value);
        files.add(XFile(file.path));
      }

      await _shareOrSave(files, dir.path);
    } catch (e) {
      state = ExportState(status: ExportStatus.failed, error: e.toString());
    }
  }

  Future<Directory> _exportDirectory() async {
    if (Platform.isLinux || Platform.isWindows) {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    }
    return getTemporaryDirectory();
  }

  Future<void> _shareOrSave(List<XFile> files, String dirPath) async {
    if (Platform.isLinux || Platform.isWindows) {
      state = ExportState(
        status: ExportStatus.completed,
        savedPath: dirPath,
      );
    } else {
      await SharePlus.instance.share(ShareParams(files: files));
      state = const ExportState(status: ExportStatus.completed);
    }
  }

  void reset() {
    state = const ExportState();
  }
}

final exportProvider = NotifierProvider<ExportNotifier, ExportState>(
  ExportNotifier.new,
);
