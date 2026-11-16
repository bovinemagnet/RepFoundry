import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the OS file browser and returns the chosen file's text content,
/// or null when the user cancels. Injected as a provider so widget tests
/// can supply canned content without the platform plugin.
final importFileContentPickerProvider =
    Provider<Future<String?> Function()>((ref) {
  return () async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json'],
    );
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes(), allowMalformed: true);
  };
});
