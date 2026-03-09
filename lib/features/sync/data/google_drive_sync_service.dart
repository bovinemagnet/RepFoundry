import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../domain/sync_service.dart';

const _syncFileName = 'repfoundry_sync.json';

class GoogleDriveSyncService implements CloudSyncService {
  GoogleSignInAccount? _account;
  drive.DriveApi? _driveApi;
  bool _initialised = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> _ensureInitialised() async {
    if (_initialised) return;
    await _googleSignIn.initialize();
    _initialised = true;
  }

  Future<drive.DriveApi> _getDriveApi() async {
    if (_driveApi != null) return _driveApi!;

    await _ensureInitialised();

    _account = await _googleSignIn.authenticate(
      scopeHint: [drive.DriveApi.driveAppdataScope],
    );

    final headers = await _account!.authorizationClient.authorizationHeaders(
      [drive.DriveApi.driveAppdataScope],
      promptIfNecessary: true,
    );
    if (headers == null) {
      throw Exception('Failed to obtain Drive authorisation');
    }

    final client = _AuthenticatedClient(http.Client(), headers);
    _driveApi = drive.DriveApi(client);
    return _driveApi!;
  }

  @override
  Future<bool> isAvailable() async {
    try {
      await _ensureInitialised();
      final account = await _googleSignIn.attemptLightweightAuthentication();
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
    await _googleSignIn.disconnect();
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

/// Simple authenticated HTTP client that injects auth headers.
class _AuthenticatedClient extends http.BaseClient {
  _AuthenticatedClient(this._inner, this._headers);

  final http.Client _inner;
  final Map<String, String> _headers;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
