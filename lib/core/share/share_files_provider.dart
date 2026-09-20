import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Hands files to the platform share sheet under the given [names] (one per
/// file). Names are passed separately because `XFile.fromData` discards its
/// name on every platform but web. A provider so widget tests can capture
/// what would have been shared instead of opening the sheet.
typedef ShareFiles = Future<void> Function(
  List<XFile> files,
  List<String> names,
);

final shareFilesProvider = Provider<ShareFiles>(
  (ref) => (files, names) => SharePlus.instance.share(
        ShareParams(files: files, fileNameOverrides: names),
      ),
);
