import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

import '../domain/sync_service.dart';

const _syncFileName = 'repfoundry_sync.json';

class GoogleDriveSyncService implements CloudSyncService {
  GoogleSignInAccount? _account;
  drive.DriveApi? _driveApi;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  Future<drive.DriveApi> _getDriveApi() async {
    if (_driveApi != null) return _driveApi!;

    _account = await _googleSignIn.signIn();
    if (_account == null) {
      throw Exception('Google Sign-In was cancelled');
    }

    final auth = await _account!.authentication;
    final credentials = AccessCredentials(
      AccessToken(
        'Bearer',
        auth.accessToken!,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      [drive.DriveApi.driveAppdataScope],
    );

    final client = authenticatedClient(http.Client(), credentials);
    _driveApi = drive.DriveApi(client);
    return _driveApi!;
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final account = await _googleSignIn.signInSilently();
      return account != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> uploadSnapshot(String jsonData) async {
    final api = await _getDriveApi();
    final media = drive.Media(
      Stream.value(utf8.encode(jsonData)),
      utf8.encode(jsonData).length,
    );

    final existingId = await _findSyncFileId(api);

    if (existingId != null) {
      await api.files.update(
        drive.File(),
        existingId,
        uploadMedia: media,
      );
    } else {
      final file = drive.File()
        ..name = _syncFileName
        ..parents = ['appDataFolder'];
      await api.files.create(file, uploadMedia: media);
    }
  }

  @override
  Future<String?> downloadSnapshot() async {
    final api = await _getDriveApi();
    final fileId = await _findSyncFileId(api);
    if (fileId == null) return null;

    final response = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (response is! drive.Media) return null;

    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }

  @override
  Future<void> deleteCloudData() async {
    final api = await _getDriveApi();
    final fileId = await _findSyncFileId(api);
    if (fileId != null) {
      await api.files.delete(fileId);
    }
    await _googleSignIn.signOut();
    _driveApi = null;
    _account = null;
  }

  Future<String?> _findSyncFileId(drive.DriveApi api) async {
    final fileList = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_syncFileName'",
      $fields: 'files(id)',
    );
    final files = fileList.files;
    if (files == null || files.isEmpty) return null;
    return files.first.id;
  }
}
