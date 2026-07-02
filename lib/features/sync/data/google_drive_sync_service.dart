import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../domain/sync_service.dart';

const _syncFileName = 'repfoundry_sync.json';
const _driveScopes = [drive.DriveApi.driveAppdataScope];

class GoogleDriveSyncService implements CloudSyncService {
  GoogleDriveSyncService() : _injectedApi = null;

  /// Bypasses Google sign-in and uses [api] directly, so the Drive file
  /// handling can be tested without platform channels.
  @visibleForTesting
  GoogleDriveSyncService.withApiForTesting(drive.DriveApi api)
      : _injectedApi = api;

  final drive.DriveApi? _injectedApi;

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
    final injectedApi = _injectedApi;
    if (injectedApi != null) return action(injectedApi);

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
      $fields: 'files(id, createdTime)',
    );
    final files = fileList.files;
    if (files == null || files.isEmpty) return null;
    if (files.length == 1) return files.first.id;

    // Two devices racing their first sync can each create the file (Drive
    // allows duplicate names in appDataFolder), after which each device may
    // read and write a different copy — a permanent split-brain. Collapse
    // duplicates to a deterministic winner and delete the rest. Deleting a
    // duplicate only discards its uploaded merge; the device that wrote it
    // still holds all of its data locally and re-merges into the winner on
    // its next sync.
    final sorted = [...files]..sort(_compareSyncFiles);
    final winner = sorted.first;
    for (final loser in sorted.skip(1)) {
      final loserId = loser.id;
      if (loserId == null) continue;
      try {
        await api.files.delete(loserId);
      } catch (_) {
        // Best-effort: a leftover duplicate is collapsed on a later sync,
        // and reads/writes already target the winner.
      }
    }
    return winner.id;
  }

  /// Orders duplicate sync files so every device picks the same winner:
  /// earliest createdTime first, missing createdTime last, ties broken by id.
  static int _compareSyncFiles(drive.File a, drive.File b) {
    final aTime = a.createdTime;
    final bTime = b.createdTime;
    if (aTime != null && bTime != null && aTime != bTime) {
      return aTime.compareTo(bTime);
    }
    if (aTime != null && bTime == null) return -1;
    if (aTime == null && bTime != null) return 1;
    return (a.id ?? '').compareTo(b.id ?? '');
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
