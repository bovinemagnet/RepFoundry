/// Whether this platform may host the MCP server.
///
/// Desktop only: macOS, Windows and Linux. Web is checked first because the
/// desktop flags cannot be read there. iOS and Android pass no flags.
bool isMcpHostSupported({
  bool isWeb = false,
  bool isMacOS = false,
  bool isWindows = false,
  bool isLinux = false,
}) {
  if (isWeb) return false;
  return isMacOS || isWindows || isLinux;
}
