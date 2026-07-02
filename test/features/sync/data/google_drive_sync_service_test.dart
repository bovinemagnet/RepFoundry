import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:rep_foundry/features/sync/data/google_drive_sync_service.dart';

/// Fake Drive API that dispatches the few calls the sync service makes via
/// [noSuchMethod], so the fakes don't have to track googleapis signatures.
class _FakeFilesResource implements drive.FilesResource {
  _FakeFilesResource(this.listResult);

  List<drive.File> listResult;
  final List<String> deletedIds = [];
  final Set<String> failDeletes = {};
  String? downloadedFileId;
  String? updatedFileId;
  bool created = false;
  String downloadContent = '{"remote":"data"}';

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #list:
        return Future.value(drive.FileList()..files = List.of(listResult));
      case #delete:
        final id = invocation.positionalArguments.first as String;
        deletedIds.add(id);
        listResult.removeWhere((f) => f.id == id);
        if (failDeletes.contains(id)) {
          return Future<void>.error(Exception('delete failed'));
        }
        return Future<void>.value();
      case #get:
        downloadedFileId = invocation.positionalArguments.first as String;
        final bytes = utf8.encode(downloadContent);
        return Future<Object>.value(
          drive.Media(Stream.value(bytes), bytes.length),
        );
      case #update:
        updatedFileId = invocation.positionalArguments[1] as String;
        return Future.value(drive.File());
      case #create:
        created = true;
        return Future.value(drive.File()..id = 'created-id');
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeDriveApi implements drive.DriveApi {
  _FakeDriveApi(this.filesResource);

  final _FakeFilesResource filesResource;

  @override
  drive.FilesResource get files => filesResource;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

drive.File _file(String id, {DateTime? createdTime}) => drive.File()
  ..id = id
  ..createdTime = createdTime;

void main() {
  group('GoogleDriveSyncService duplicate sync files', () {
    test('picks the earliest-created file and deletes the duplicates',
        () async {
      final filesResource = _FakeFilesResource([
        _file('newer', createdTime: DateTime.utc(2026, 5, 2)),
        _file('oldest', createdTime: DateTime.utc(2026, 5, 1)),
        _file('newest', createdTime: DateTime.utc(2026, 5, 3)),
      ]);
      final service = GoogleDriveSyncService.withApiForTesting(
          _FakeDriveApi(filesResource));

      final content = await service.downloadSnapshot();

      expect(content, '{"remote":"data"}');
      expect(filesResource.downloadedFileId, 'oldest');
      expect(filesResource.deletedIds, unorderedEquals(['newer', 'newest']));
    });

    test('breaks a createdTime tie deterministically by id', () async {
      final created = DateTime.utc(2026, 5, 1);
      final filesResource = _FakeFilesResource([
        _file('bbb', createdTime: created),
        _file('aaa', createdTime: created),
      ]);
      final service = GoogleDriveSyncService.withApiForTesting(
          _FakeDriveApi(filesResource));

      await service.downloadSnapshot();

      expect(filesResource.downloadedFileId, 'aaa');
      expect(filesResource.deletedIds, ['bbb']);
    });

    test('a file without createdTime loses to one that has it', () async {
      final filesResource = _FakeFilesResource([
        _file('no-timestamp'),
        _file('timestamped', createdTime: DateTime.utc(2026, 5, 1)),
      ]);
      final service = GoogleDriveSyncService.withApiForTesting(
          _FakeDriveApi(filesResource));

      await service.downloadSnapshot();

      expect(filesResource.downloadedFileId, 'timestamped');
      expect(filesResource.deletedIds, ['no-timestamp']);
    });

    test('a failed duplicate delete is swallowed and the winner still used',
        () async {
      final filesResource = _FakeFilesResource([
        _file('winner', createdTime: DateTime.utc(2026, 5, 1)),
        _file('stubborn', createdTime: DateTime.utc(2026, 5, 2)),
      ]);
      filesResource.failDeletes.add('stubborn');
      final service = GoogleDriveSyncService.withApiForTesting(
          _FakeDriveApi(filesResource));

      final content = await service.downloadSnapshot();

      expect(content, '{"remote":"data"}');
      expect(filesResource.downloadedFileId, 'winner');
    });

    test('upload updates the deterministic winner when duplicates exist',
        () async {
      final filesResource = _FakeFilesResource([
        _file('loser', createdTime: DateTime.utc(2026, 5, 2)),
        _file('winner', createdTime: DateTime.utc(2026, 5, 1)),
      ]);
      final service = GoogleDriveSyncService.withApiForTesting(
          _FakeDriveApi(filesResource));

      await service.uploadSnapshot('{"local":"data"}');

      expect(filesResource.updatedFileId, 'winner');
      expect(filesResource.deletedIds, ['loser']);
      expect(filesResource.created, isFalse);
    });

    test('a single file is used as-is with no deletes', () async {
      final filesResource = _FakeFilesResource([
        _file('only', createdTime: DateTime.utc(2026, 5, 1)),
      ]);
      final service = GoogleDriveSyncService.withApiForTesting(
          _FakeDriveApi(filesResource));

      await service.downloadSnapshot();

      expect(filesResource.downloadedFileId, 'only');
      expect(filesResource.deletedIds, isEmpty);
    });

    test('no sync file yet: download returns null and upload creates one',
        () async {
      final filesResource = _FakeFilesResource([]);
      final service = GoogleDriveSyncService.withApiForTesting(
          _FakeDriveApi(filesResource));

      expect(await service.downloadSnapshot(), isNull);

      await service.uploadSnapshot('{"local":"data"}');
      expect(filesResource.created, isTrue);
      expect(filesResource.updatedFileId, isNull);
    });
  });
}
