import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../domain/mcp_host_support.dart';

/// [isMcpHostSupported] for the platform this app is running on.
bool mcpHostSupportedOnThisPlatform() {
  // dart:io's Platform getters throw on web, so decide that first.
  if (kIsWeb) return isMcpHostSupported(isWeb: true);
  return isMcpHostSupported(
    isMacOS: Platform.isMacOS,
    isWindows: Platform.isWindows,
    isLinux: Platform.isLinux,
  );
}
