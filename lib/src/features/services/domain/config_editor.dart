import '../../../shared/debug_constants.dart';
import '../../../shared/debug_strings.dart';

/// Value type of a config entry, surfaced as a chip (mirrors the Storage prefs
/// type chips).
enum DebugLensConfigType {
  boolean,
  integer,
  double,
  string;

  /// Short label shown as the type chip.
  String get label => switch (this) {
    DebugLensConfigType.boolean => 'bool',
    DebugLensConfigType.integer => 'int',
    DebugLensConfigType.double => 'double',
    DebugLensConfigType.string => 'String',
  };

  /// Whether [value] parses as this type. The inspector blocks saving an edit
  /// that fails this check, so a host never receives an unparseable string.
  bool accepts(String value) => switch (this) {
    DebugLensConfigType.boolean =>
      value == DebugConstants.trueValue || value == DebugConstants.falseValue,
    DebugLensConfigType.integer => int.tryParse(value) != null,
    DebugLensConfigType.double => _parsesAsDouble(value),
    DebugLensConfigType.string => true,
  };
}

/// Top-level so `double` resolves to `dart:core`'s type — inside the enum body
/// the `double` *value* shadows it.
bool _parsesAsDouble(String value) => double.tryParse(value) != null;

/// One config parameter shown on an editable service screen.
class DebugLensConfigEntry {
  final String key;

  /// Effective value in string form (parsed per [type] when edited).
  final String value;
  final DebugLensConfigType type;

  /// The source-of-truth (remote) value in string form, if any — shown as the
  /// starting point when editing. Falls back to [value] when null.
  final String? sourceValue;

  /// Whether this value is currently a device-local override (vs the remote
  /// source of truth).
  final bool overridden;

  const DebugLensConfigEntry({
    required this.key,
    required this.value,
    required this.type,
    this.sourceValue,
    this.overridden = false,
  });
}

/// Optional capability that lets the inspector edit a service's values
/// on-device — e.g. Remote Config overrides. Provider-agnostic: it is just a
/// typed key/value store with a device-local override mode, so it fits Firebase
/// Remote Config, AWS AppConfig, LaunchDarkly, or a hand-rolled flag store.
///
/// A service exposes one via `DebugLensService.editor`; when present, the
/// service screen renders a source toggle and (in override mode) editable,
/// type-tagged rows instead of the read-only list.
///
/// **`extends` this, don't `implements` it** — only [overrideEnabled],
/// [entries], [setOverrideEnabled] and [setValue] are required; the rest have
/// working defaults that `implements` would force you to re-declare.
abstract class DebugLensConfigEditor {
  /// Whether device-local override ("custom") mode is on. Defaults off.
  bool get overrideEnabled;

  /// Label for the source-of-truth side of the toggle — name your provider
  /// here (e.g. `'Firebase'`). The override side is always "Custom".
  String get sourceLabel => DebugStrings.serviceSourceRemote;

  /// Whether edits take effect only after an app restart. When true the
  /// inspector confirms with an "applies on restart" dialog *before* switching
  /// source, so cancelling leaves the current mode untouched. Individual edits
  /// and resets within override mode are not re-confirmed.
  bool get requiresRestart => true;

  /// Whether any value is currently overridden (drives the Reset action).
  /// Derived from [entries] by default; override it if that is cheaper.
  bool get hasOverrides => entries.any((e) => e.overridden);

  /// Current entries — reflecting the pending overrides when [overrideEnabled].
  List<DebugLensConfigEntry> get entries;

  /// Toggles override mode. Turning it off resets every value to the source of
  /// truth.
  Future<void> setOverrideEnabled(bool enabled);

  /// Overrides [key] with [value]. The inspector guarantees [value] satisfies
  /// the entry's [DebugLensConfigType.accepts] before calling this.
  Future<void> setValue(String key, String value);

  /// Clears all device overrides back to the source of truth, staying in
  /// override mode. No-op by default.
  Future<void> resetOverrides() async {}
}
