import 'dart:convert';

import 'package:debug_lens/debug_lens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One Remote Config parameter: its key, type and Firebase (source-of-truth)
/// value.
class _RcParam {
  final String key;
  final DebugLensConfigType type;
  final Object value;
  const _RcParam(this.key, this.type, this.value);
}

/// In-memory stand-in for `FirebaseRemoteConfig` that also implements the
/// DebugLens [DebugLensConfigEditor] capability. Each param has a Firebase
/// value (the source of truth); when device-local override ("custom") mode is
/// on, persisted overrides win. Overrides + the mode flag are stored in
/// SharedPreferences and applied on the next app start — matching how Remote
/// Config "activates" fetched values.
class MockRemoteConfig extends DebugLensConfigEditor {
  MockRemoteConfig._() {
    for (final p in _params) {
      _active[p.key] = p.value;
    }
  }
  static final MockRemoteConfig instance = MockRemoteConfig._();

  static const List<_RcParam> _params = [
    _RcParam('home_header_title', DebugLensConfigType.string, 'Your day'),
    _RcParam('show_summary_card', DebugLensConfigType.boolean, true),
    _RcParam(
      'promo_banner_text',
      DebugLensConfigType.string,
      '🎉 20% off Pro — this week only',
    ),
    _RcParam('home_layout_experiment', DebugLensConfigType.string, 'variant_b'),
    _RcParam('notification_batch_size', DebugLensConfigType.integer, 4),
    _RcParam('discount_percentage', DebugLensConfigType.double, 12.5),
    _RcParam('api_timeout_seconds', DebugLensConfigType.integer, 30),
  ];

  static const _kCustom = 'mock_rc_custom_enabled';
  static const _kOverrides = 'mock_rc_overrides';

  SharedPreferences? _prefs;
  bool _customEnabled = false;
  Map<String, String> _overrides = {};

  /// Values active for this session (recomputed only on [fetchAndActivate]).
  final Map<String, Object> _active = {};

  DateTime? lastFetchTime;
  String lastFetchStatus = 'noFetchYet';

  _RcParam _param(String key) => _params.firstWhere((p) => p.key == key);

  /// Loads persisted overrides + the custom flag, then activates the effective
  /// values for this session (overrides win only while custom mode is on).
  Future<bool> fetchAndActivate(SharedPreferences prefs) async {
    _prefs = prefs;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _customEnabled = prefs.getBool(_kCustom) ?? false;
    final raw = prefs.getString(_kOverrides);
    _overrides = raw == null
        ? {}
        : Map<String, String>.from(jsonDecode(raw) as Map);
    for (final p in _params) {
      final override = _customEnabled ? _overrides[p.key] : null;
      // A persisted override could predate a type change; fall back rather
      // than crash startup.
      _active[p.key] = override != null && p.type.accepts(override)
          ? _parse(p.type, override)
          : p.value;
    }
    lastFetchTime = DateTime.now();
    lastFetchStatus = 'success';
    return true;
  }

  /// Parses [v] as [type]. Callers must have checked
  /// [DebugLensConfigType.accepts] first — this throws rather than silently
  /// coercing a bad value to zero.
  static Object _parse(DebugLensConfigType type, String v) {
    switch (type) {
      case DebugLensConfigType.boolean:
        return v.toLowerCase() == 'true';
      case DebugLensConfigType.integer:
        return int.parse(v);
      case DebugLensConfigType.double:
        return double.parse(v);
      case DebugLensConfigType.string:
        return v;
    }
  }

  // --- Reads (used by the app) ---------------------------------------------

  bool getBool(String key) =>
      _active[key] is bool ? _active[key] as bool : false;

  String getString(String key) => _active[key]?.toString() ?? '';

  int getInt(String key) =>
      _active[key] is num ? (_active[key] as num).toInt() : 0;

  double getDouble(String key) =>
      _active[key] is num ? (_active[key] as num).toDouble() : 0.0;

  // --- DebugLensConfigEditor -----------------------------------------------

  @override
  bool get overrideEnabled => _customEnabled;

  /// Names the source of truth on the screen's toggle (vs "Custom").
  @override
  String get sourceLabel => 'Firebase';

  @override
  bool get requiresRestart => true;

  // `hasOverrides` is left to the default, which derives it from [entries].

  @override
  List<DebugLensConfigEntry> get entries => [
    for (final p in _params)
      DebugLensConfigEntry(
        key: p.key,
        type: p.type,
        value: _customEnabled && _overrides.containsKey(p.key)
            ? _overrides[p.key]!
            : '${p.value}',
        sourceValue: '${p.value}',
        overridden: _customEnabled && _overrides.containsKey(p.key),
      ),
  ];

  @override
  Future<void> setOverrideEnabled(bool enabled) async {
    _customEnabled = enabled;
    await _prefs?.setBool(_kCustom, enabled);
    // Turning custom mode off resets everything to the Firebase source of truth.
    if (!enabled) {
      _overrides = {};
      await _prefs?.remove(_kOverrides);
    }
  }

  @override
  Future<void> setValue(String key, String value) async {
    // The inspector only hands over values that pass `accepts`; assert it here
    // so a programmatic caller can't slip an unparseable one into the store.
    assert(
      _param(key).type.accepts(value),
      'Value "$value" is not a valid ${_param(key).type.label} for "$key"',
    );
    _overrides[key] = value;
    await _prefs?.setString(_kOverrides, jsonEncode(_overrides));
  }

  @override
  Future<void> resetOverrides() async {
    // Clear device overrides but stay in custom mode.
    _overrides = {};
    await _prefs?.remove(_kOverrides);
  }
}
