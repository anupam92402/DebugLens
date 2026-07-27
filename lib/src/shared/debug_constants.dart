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

  /// Placeholder shown in place of a hidden (encrypted or sensitive) value.
  static const String maskedValue = '••••••';

  /// Canonical string form of a boolean, used when parsing and emitting
  /// editable config values (see `DebugLensConfigType`).
  static const String trueValue = 'true';
  static const String falseValue = 'false';

  // SharedPreferences keys DebugLens persists its own state under.

  /// Access role for the panel (see `DebugRoleController`).
  static const String rolePrefsKey = 'debug_lens_role';

  /// Navigation screen's eye toggle (hide `debug_lens/` routes).
  static const String navHideInternalPrefsKey = 'debug_lens_nav_hide_internal';

  /// The dashboard's tile order, as a JSON list of route names.
  static const String dashboardOrderPrefsKey = 'debug_lens_dashboard_order';

  /// Routes a tester may open, as a JSON list of route names.
  static const String testerRoutesPrefsKey = 'debug_lens_tester_routes';

  /// Whether the tester role is available at all (`'true'` / `'false'`).
  static const String testerEnabledPrefsKey = 'debug_lens_tester_enabled';

  /// Device-local app-version override. Absent when none is set.
  static const String appVersionPrefsKey = 'debug_lens_app_version';

  /// Per-feature retention limits, as a JSON `limit name -> int` map.
  static const String limitsPrefsKey = 'debug_lens_limits';

  /// Cap on health-check reports kept for the session. They hold stack traces,
  /// and nobody scrolls back past a handful.
  static const int maxHealthReports = 20;

  /// Share of the screen height a modal bottom sheet may take. Past this a
  /// long list scrolls inside the sheet instead of pushing it off the top.
  static const double bottomSheetMaxHeightFraction = 0.6;

  /// Whether the Services config editor is in device-override ("custom") mode.
  static const String configCustomPrefsKey = 'debug_lens_config_custom';

  /// The device overrides themselves, as a JSON `key -> string` map.
  static const String configOverridesPrefsKey = 'debug_lens_config_overrides';

  /// Prefix on the tag the logger prints, e.g. `Flutter-Log-auth`.
  static const String logTagPrefix = 'Flutter-Log';

  /// Prefix for the Logs screen's per-source capture switches. The full key is
  /// this plus the origin's `name` — see `DebugLogOrigin.prefsKey`.
  static const String logCapturePrefsKeyPrefix = 'debug_lens_log_capture_';
}
