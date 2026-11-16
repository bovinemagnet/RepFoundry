import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/settings/presentation/providers/import_file_picker_provider.dart';
import 'package:share_plus/share_plus.dart' show XFile;

final class _FakeFile extends PlatformFile {
  _FakeFile(this.bytes);

  final Uint8List bytes;

  @override
  String get name => 'backup.json';

  @override
  Uri get uri => Uri.parse('content://picker/backup.json');

  @override
  XFile get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => bytes.length;

  @override
  Future<int?> length() async => bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => bytes;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

class _FakePicker extends FilePickerPlatform {
  _FakePicker(this.result);

  final PlatformFile? result;
  FileType? type;
  List<String>? allowedExtensions;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    this.type = type;
    this.allowedExtensions = allowedExtensions;
    return result;
  }
}

void main() {
  late FilePickerPlatform original;

  setUp(() => original = FilePickerPlatform.instance);
  tearDown(() => FilePickerPlatform.instance = original);

  Future<String?> pick() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container.read(importFileContentPickerProvider)();
  }

  test('returns the picked file as text, offering only csv and json', () async {
    final picker = _FakePicker(
      _FakeFile(Uint8List.fromList(utf8.encode('{"weight": "80 kg"}'))),
    );
    FilePickerPlatform.instance = picker;

    expect(await pick(), '{"weight": "80 kg"}');
    expect(picker.type, FileType.custom);
    expect(picker.allowedExtensions, ['csv', 'json']);
  });

  test('decodes malformed UTF-8 rather than throwing', () async {
    FilePickerPlatform.instance =
        _FakePicker(_FakeFile(Uint8List.fromList([0x61, 0xff, 0x62])));

    expect(await pick(), 'a�b');
  });

  test('returns null when the user cancels', () async {
    FilePickerPlatform.instance = _FakePicker(null);

    expect(await pick(), isNull);
  });
}
