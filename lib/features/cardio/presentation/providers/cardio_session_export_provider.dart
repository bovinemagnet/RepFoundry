import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers.dart';
import '../../../../core/share/share_files_provider.dart';
import '../../application/cardio_session_exporter.dart';
import '../../domain/models/cardio_session.dart';

/// Shares a saved cardio session's recordings as two files: a GPX track
/// and a heart-rate CSV. Only files with something in them are shared.
class CardioSessionExport {
  const CardioSessionExport(this._ref);

  final Ref _ref;

  Future<void> call({
    required CardioSession session,
    required String exerciseName,
    required DateTime startedAt,
  }) async {
    final repo = _ref.read(cardioSessionRepositoryProvider);
    final points = await repo.getTrackPoints(session.id);
    final samples = await repo.getHeartRateSamples(session.id);
    final stem = CardioSessionExporter.fileStem(
      exerciseName: exerciseName,
      startedAt: startedAt,
    );

    final files = <XFile>[];
    final names = <String>[];
    if (points.isNotEmpty) {
      files.add(XFile.fromData(
        utf8.encode(CardioSessionExporter.gpx(
          session,
          exerciseName: exerciseName,
          startedAt: startedAt,
          points: points,
        )),
        mimeType: 'application/gpx+xml',
      ));
      names.add('$stem.gpx');
    }
    if (samples.isNotEmpty) {
      files.add(XFile.fromData(
        utf8.encode(CardioSessionExporter.heartRateCsv(samples)),
        mimeType: 'text/csv',
      ));
      names.add('$stem-heart-rate.csv');
    }
    if (files.isEmpty) return;
    await _ref.read(shareFilesProvider)(files, names);
  }
}

final cardioSessionExportProvider =
    Provider<CardioSessionExport>((ref) => CardioSessionExport(ref));
