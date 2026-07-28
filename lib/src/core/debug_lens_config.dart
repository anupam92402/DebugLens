/// The master switch, set by the host through `DebugLens.debugLensEnabled`.
///
/// Lives here rather than on `DebugLens` so everything under `src/` can consult
/// it without importing the public entry point back.
///
/// Read by every write path — the store, the logger, the pushed service stores,
/// the config and version overrides — and by `DebugLens.wrap`. When it is false
/// DebugLens holds nothing, persists nothing and overrides nothing.
class DebugLensConfig {
  DebugLensConfig._();

  /// Defaults to on so the package works the moment it is wired up. Turning it
  /// off for release builds is the host's call — see `DebugLens.debugLensEnabled`.
  static bool enabled = true;
}
