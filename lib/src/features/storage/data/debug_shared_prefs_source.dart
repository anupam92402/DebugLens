import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pref_entry.dart';

/// Pull-based provider of the app's SharedPreferences snapshot.
///
/// DebugLens calls this each time the Storage screen builds (and on manual
/// refresh) and renders the result; it keeps no copy. Register it from the
/// host's SharedPreferences wrapper so DebugLens stays generic — it never
/// imports any client package.
///
/// ```dart
/// DebugLens.sharedPrefsSource = () => [
///       for (final e in prefs.dumpAll())
///         DebugLensPrefEntry(key: e.key, value: e.value, encrypted: e.encrypted),
///     ];
/// ```
typedef DebugLensSharedPrefsSource = List<DebugLensPrefEntry> Function();

/// Holds the host-registered [DebugLensSharedPrefsSource]. Static + global so
/// the host can wire it once (e.g. after SharedPreferences is initialized).
class DebugLensSharedPrefs {
  DebugLensSharedPrefs._();

  /// The current source, or `null` when the host hasn't registered one (the
  /// Storage screen then shows its empty state).
  static DebugLensSharedPrefsSource? source;

  // DebugLens's own persisted flags (nav eye toggle, …) also go through this
  // class so feature screens never import shared_preferences directly.

  /// Reads a bool persisted under [key]; `null` when unset or storage is
  /// unavailable (caller keeps its in-memory default).
  static Future<bool?> getBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (_) {
      return null;
    }
  }

  /// Persists [value] under [key]. Failures are swallowed — the in-memory
  /// value still applies for the session.
  static Future<void> setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {
      // Persistence failed — nothing to do.
    }
  }
}
