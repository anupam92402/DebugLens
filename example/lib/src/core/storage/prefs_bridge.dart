import 'package:debug_lens/debug_lens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bridges the app's real [SharedPreferences] to DebugLens. The app uses the
/// plain package; this only maps a live snapshot into `DebugLensPrefEntry`s
/// for the Storage screen — debug_lens never touches shared_preferences here.
abstract final class PrefsBridge {
  /// Keys the app treats as secrets — in a real app these would live in an
  /// encrypted-prefs wrapper. DebugLens flags them with a `*`.
  static const Set<String> _encryptedKeys = {'auth_token', 'refresh_token'};

  /// Writes a spread of demo values (one per type, plus a couple of
  /// "encrypted" keys), each only when absent — so keys added later still
  /// appear on the next launch of an already-seeded install.
  static Future<void> seedIfEmpty(SharedPreferences prefs) async {
    Future<void> put(String key, Future<bool> Function() write) async {
      if (!prefs.containsKey(key)) await write();
    }

    await put(
      'onboarding_complete',
      () => prefs.setBool('onboarding_complete', true),
    );
    await put('launch_count', () => prefs.setInt('launch_count', 7));
    await put('volume', () => prefs.setDouble('volume', 0.8));
    await put('username', () => prefs.setString('username', 'anupam'));
    await put(
      'recent_searches',
      () =>
          prefs.setStringList('recent_searches', ['flutter', 'dart', 'drift']),
    );
    await put(
      'auth_token',
      () => prefs.setString('auth_token', 'eyJhbGciOiJIUzI1NiJ9.demo.token'),
    );
    await put(
      'refresh_token',
      () => prefs.setString('refresh_token', 'rt_9f2c_demo_refresh'),
    );
  }

  /// Live snapshot of every pref as a `DebugLensPrefEntry`. Called by DebugLens
  /// on demand; no copy is retained. Keys in [_encryptedKeys] are marked
  /// encrypted so the Storage screen shows the `*` badge.
  static List<DebugLensPrefEntry> snapshot(SharedPreferences prefs) => [
    for (final key in prefs.getKeys())
      DebugLensPrefEntry(
        key: key,
        value: '${prefs.get(key)}',
        type: _typeOf(prefs.get(key)),
        encrypted: _encryptedKeys.contains(key),
      ),
  ];

  static DebugLensPrefType _typeOf(Object? value) {
    if (value is bool) return DebugLensPrefType.boolean;
    if (value is int) return DebugLensPrefType.integer;
    if (value is double) return DebugLensPrefType.double;
    if (value is List) return DebugLensPrefType.stringList;
    if (value is String) return DebugLensPrefType.string;
    return DebugLensPrefType.unknown;
  }
}
