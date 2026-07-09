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
}
