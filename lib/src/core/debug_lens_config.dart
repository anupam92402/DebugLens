/// The master switch, set by the host through `DebugLens.debugLensEnabled`.
class DebugLensConfig {
  DebugLensConfig._();

  /// Defaults to on so the package works the moment it is wired up. Turning it
  /// off for release builds is the host's call — see `DebugLens.debugLensEnabled`.
  static bool enabled = true;
}
