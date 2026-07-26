import 'dart:convert';

import '../../../shared/debug_constants.dart';
import '../../../shared/debug_strings.dart';
import '../../storage/data/debug_shared_prefs_source.dart';
import '../domain/config_editor.dart';
import 'debug_service_source.dart';

/// DebugLens's own store for editable config, and the only implementation of
/// [DebugLensConfigEditor].
///
/// The host hands its source-of-truth values over once through
/// `DebugLens.registerConfig` and asks [activatedValue] whether to use an
/// override. Everything else — which keys are overridden, the custom-mode flag,
/// and persisting both — lives here, so a host never writes that code.
///
/// **Edits apply on the next app start.** [load] snapshots the persisted
/// overrides into [_activated], which is what [activatedValue] answers from.
/// Later edits only touch [_overrides] — the map the screen renders — so a value
/// changed now shows as `custom` immediately but isn't served until relaunch.
class DebugConfigStore extends DebugLensConfigEditor {
  DebugConfigStore._();

  static final DebugConfigStore instance = DebugConfigStore._();

  /// The host's values, exactly as registered. Also the fallback the screen
  /// shows as each row's source value.
  final Map<String, Object?> _source = <String, Object?>{};

  /// Pending overrides in string form — edited from the screen, persisted, and
  /// read back at the next [load].
  final Map<String, String> _overrides = <String, String>{};

  /// Overrides in force for this session, coerced to their source value's
  /// shape. Empty when custom mode was off at startup.
  final Map<String, Object?> _activated = <String, Object?>{};

  /// Live mode — what the screen's toggle shows and edits. Reads don't consult
  /// it: [_activated] is the snapshot, so flipping the toggle takes effect on
  /// the next start just like an edit does.
  bool _customEnabled = false;

  String _sourceLabel = DebugStrings.serviceSourceRemote;

  /// The value in force for [key] — the override when one applies this session,
  /// otherwise the registered value, otherwise `null` for an unknown key.
  Object? resolvedValue(String key) => _activated[key] ?? _source[key];

  /// Takes [values] as the source of truth, loads the persisted overrides, and
  /// resolves what this session should serve. Call once at startup, awaited —
  /// [activatedValue] is only meaningful afterwards.
  Future<void> load(Map<String, Object?> values, String sourceLabel) async {
    _source
      ..clear()
      ..addAll(values);
    _sourceLabel = sourceLabel;

    _customEnabled =
        await DebugLensSharedPrefs.getBool(
          DebugConstants.configCustomPrefsKey,
        ) ??
        false;
    _overrides
      ..clear()
      ..addAll(await _readOverrides());

    _activated.clear();
    if (!_customEnabled) return;
    for (final entry in _overrides.entries) {
      /// Skip an override for a key the host no longer registers.
      if (!_source.containsKey(entry.key)) continue;
      _activated[entry.key] = _coerce(_source[entry.key], entry.value);
    }
  }

  // --- DebugLensConfigEditor -------------------------------------------------

  @override
  String get sourceLabel => _sourceLabel;

  @override
  bool get overrideEnabled => _customEnabled;

  @override
  List<DebugLensConfigEntry> get entries => [
    for (final e in _source.entries)
      DebugLensConfigEntry(
        key: e.key,
        value: _isOverridden(e.key)
            ? _coerce(e.value, _overrides[e.key]!)
            : e.value,
        sourceValue: e.value,
        overridden: _isOverridden(e.key),
      ),
  ];

  @override
  Future<void> setOverrideEnabled(bool enabled) async {
    _customEnabled = enabled;
    await DebugLensSharedPrefs.setBool(
      DebugConstants.configCustomPrefsKey,
      enabled,
    );

    /// Leaving custom mode drops the overrides with it, so the next start is
    /// unambiguously back on the host's values.
    if (!enabled) {
      _overrides.clear();
      await _writeOverrides();
    }
  }

  @override
  Future<void> setValue(String key, String value) async {
    _overrides[key] = value;
    await _writeOverrides();
  }

  @override
  Future<void> resetOverrides() async {
    _overrides.clear();
    await _writeOverrides();
  }

  // --- Internals -------------------------------------------------------------

  bool _isOverridden(String key) =>
      _customEnabled && _overrides.containsKey(key);

  Future<Map<String, String>> _readOverrides() async {
    final raw = await DebugLensSharedPrefs.getString(
      DebugConstants.configOverridesPrefsKey,
    );
    if (raw == null || raw.isEmpty) return const {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      /// Unreadable (hand-edited, or written by an older shape) — start clean
      /// rather than fail startup.
      return const {};
    }
  }

  Future<void> _writeOverrides() => DebugLensSharedPrefs.setString(
    DebugConstants.configOverridesPrefsKey,
    _overrides.isEmpty ? null : jsonEncode(_overrides),
  );

  /// Reads [raw] back in the shape of [source], falling back to it when the
  /// string doesn't fit — an override can outlive a change to its value's type.
  static Object? _coerce(Object? source, String raw) {
    if (source is bool) return raw.toLowerCase() == DebugConstants.trueValue;
    if (source is int) return int.tryParse(raw) ?? source;
    if (source is double) return double.tryParse(raw) ?? source;
    return raw;
  }
}

/// The Services-screen entry DebugLens registers for the host's config, so the
/// editable rows appear alongside the host's own read-only services.
class DebugConfigService extends DebugLensService {
  DebugConfigService({required this.name});

  @override
  final String name;

  @override
  DebugLensConfigEditor get editor => DebugConfigStore.instance;
}
