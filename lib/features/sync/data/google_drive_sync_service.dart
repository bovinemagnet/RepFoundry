import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../domain/sync_service.dart';

const _syncFileName = 'repfoundry_sync.json';
const _driveScopes = [drive.DriveApi.driveAppdataScope];

class GoogleDriveSyncService implements CloudSyncService {
  GoogleSignInAccount? _account;
  bool _initialised = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> _ensureInitialised() async {
    if (_initialised) return;
    await _googleSignIn.initialize();
    _initialised = true;
  }

  Future<GoogleSignInAccount> _getAccount({required bool interactive}) async {
    await _ensureInitialised();

    final existingAccount = _account;
    if (existingAccount != null) return existingAccount;

    final lightweightAuth = _googleSignIn.attemptLightweightAuthentication();
    final lightweightAccount =
        lightweightAuth == null ? null : await lightweightAuth;
    if (lightweightAccount != null) {
      _account = lightweightAccount;
      return lightweightAccount;
    }

    if (!interactive) {
      throw Exception('Google Drive sync is not authenticated');
    }

    if (!_googleSignIn.supportsAuthenticate()) {
      throw Exception('Google sign-in is not supported on this platform');
    }

    final account = await _googleSignIn.authenticate(scopeHint: _driveScopes);
    _account = account;
    return account;
  }

  Future<Map<String, String>> _authorizationHeaders({
    required bool interactive,
  }) async {
    final account = await _getAccount(interactive: interactive);
    final headers = await account.authorizationClient.authorizationHeaders(
      _driveScopes,
      promptIfNecessary: interactive,
    );
    if (headers == null) {
      throw Exception('Google Drive sync is not authorized');
    }
    return headers;
  }

  Future<T> _withDriveApi<T>(
    bool interactive,
    Future<T> Function(drive.DriveApi api) action,
  ) async {
    final client = _AuthenticatedClient(
      http.Client(),
      () => _authorizationHeaders(interactive: interactive),
    );
    try {
      return await action(drive.DriveApi(client));
    } finally {
      client.close();
    }
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
  Future<void> uploadSnapshot(
    String jsonData, {
    bool interactive = false,
  }) async {
    await _withDriveApi(interactive, (api) async {
      final bytes = utf8.encode(jsonData);
      final media = drive.Media(Stream.value(bytes), bytes.length);

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
    });
  }

  @override
  Future<String?> downloadSnapshot({bool interactive = false}) async {
    return _withDriveApi(interactive, (api) async {
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
    });
  }

  @override
  Future<void> deleteCloudData({bool interactive = false}) async {
    await _withDriveApi(interactive, (api) async {
      final fileId = await _findSyncFileId(api);
      if (fileId != null) {
        await api.files.delete(fileId);
      }
    });
    await _googleSignIn.disconnect();
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
  _AuthenticatedClient(this._inner, this._headersProvider);

  final http.Client _inner;
  final Future<Map<String, String>> Function() _headersProvider;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers.addAll(await _headersProvider());
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
