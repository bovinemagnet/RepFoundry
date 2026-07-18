import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the OS file browser and returns the chosen file's text content,
/// or null when the user cancels. Injected as a provider so widget tests
/// can supply canned content without the platform plugin.
final importFileContentPickerProvider =
    Provider<Future<String?> Function()>((ref) {
  return () async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null) return null;
    final bytes = file.bytes;
    if (bytes != null) return utf8.decode(bytes, allowMalformed: true);
    final path = file.path;
    if (path == null) return null;
    return File(path).readAsString();
  };
});
