/// Non-display constant tokens used across DebugLens.
///
/// These are the small fixed markers rendered in place of missing or special
/// data — not sentences. Human-readable UI *copy* lives in `DebugStrings`;
/// this file holds the sentinels/placeholders (and similar value constants)
/// so there is a single source of truth for each.
class DebugConstants {
  DebugConstants._();

  /// Placeholder shown where a value is missing/empty (en dash).
  static const String emptyValue = '—';

  /// Placeholder for a field that doesn't apply (e.g. content/response type).
  static const String notAvailable = 'N/A';

  /// Marker shown as the status of an in-flight request.
  static const String pendingIndicator = '•••';

  /// Placeholder shown where a bloc state / value is unknown.
  static const String unknownValue = '?';

  /// Suffix marking a SharedPreferences entry stored via encrypted prefs.
  static const String encryptedMarker = '*';

  // SharedPreferences keys DebugLens persists its own state under.

  /// Access role for the panel (see `DebugRoleController`).
  static const String rolePrefsKey = 'debug_lens_role';

  /// Navigation screen's eye toggle (hide `debug_lens/` routes).
  static const String navHideInternalPrefsKey = 'debug_lens_nav_hide_internal';
}
