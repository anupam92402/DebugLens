import 'package:flutter/foundation.dart';

/// One SharedPreferences entry, as handed to DebugLens for display.
///
/// [value] is always the readable string form (the underlying store serializes
/// scalars to text before persisting, so there is no original int/bool/double
/// type to recover). [encrypted] marks entries that were stored through the
/// app's encrypted preferences (vs. plaintext keys written by plugins or the
/// framework) — the Storage screen flags these with a `*`.
@immutable
class DebugLensPrefEntry {
  final String key;
  final String value;
  final bool encrypted;

  const DebugLensPrefEntry({
    required this.key,
    required this.value,
    this.encrypted = false,
  });
}

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
