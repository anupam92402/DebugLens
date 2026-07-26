import '../../../shared/debug_constants.dart';
import '../../../shared/debug_strings.dart';

/// Value type of a config entry, surfaced as a chip (mirrors the Storage prefs
/// type chips). Never named by the host — inferred from the value it passes,
/// see [DebugLensConfigEntry.new].
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

/// Infers a config type from a live value. Anything that isn't a `bool`, `int`
/// or `double` reads as a string, so a host can hand over whatever it has.
/// Top-level for the same shadowing reason as [_parsesAsDouble].
DebugLensConfigType _typeOf(Object? value) {
  if (value is bool) return DebugLensConfigType.boolean;
  if (value is int) return DebugLensConfigType.integer;
  if (value is double) return DebugLensConfigType.double;
  return DebugLensConfigType.string;
}

/// One config parameter shown on an editable service screen.
///
/// Build them one at a time in a loop, or hand over a whole map with
/// [fromMap] — whichever fits how your config is held.
class DebugLensConfigEntry {
  final String key;

  /// Effective value in string form — what the row shows and the editor edits.
  final String value;

  /// Inferred from the value passed to the constructor; drives the type chip,
  /// the keyboard, and edit validation.
  final DebugLensConfigType type;

  /// The source-of-truth (remote) value in string form, if any — shown as the
  /// starting point when editing. Falls back to [value] when null.
  final String? sourceValue;

  /// Whether this value is currently a device-local override (vs the remote
  /// source of truth).
  final bool overridden;

  /// Takes the **live** value — `true`, `4`, `12.5`, `'variant_b'` — and works
  /// the type out from it, so you never name one. Values are held in string
  /// form; anything that isn't a `bool` / `int` / `double` is treated as a
  /// string.
  DebugLensConfigEntry({
    required this.key,
    required Object? value,
    Object? sourceValue,
    this.overridden = false,
  }) : value = '${value ?? ''}',
       type = _typeOf(value),
       sourceValue = sourceValue?.toString();

  /// Builds an entry per key in [values] — the bulk alternative to looping.
  /// [sourceValues] supplies the remote value per key, and [overridden] names
  /// the keys currently carrying a device override.
  static List<DebugLensConfigEntry> fromMap(
    Map<String, Object?> values, {
    Map<String, Object?> sourceValues = const {},
    Set<String> overridden = const {},
  }) => [
    for (final e in values.entries)
      DebugLensConfigEntry(
        key: e.key,
        value: e.value,
        sourceValue: sourceValues[e.key],
        overridden: overridden.contains(e.key),
      ),
  ];
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
