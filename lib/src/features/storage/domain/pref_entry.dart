import 'package:flutter/foundation.dart';

/// The original type of a SharedPreferences value, so the Storage screen can
/// show a type label even though [DebugLensPrefEntry.value] is a string.
enum DebugLensPrefType {
  /// Stored with `setBool`.
  boolean,

  /// Stored with `setInt`.
  integer,

  /// Stored with `setDouble`.
  double,

  /// Stored with `setString`.
  string,

  /// Stored with `setStringList`.
  stringList,

  /// Type not reported by the source.
  unknown;

  /// Short label shown as the type chip.
  @internal
  String get label => switch (this) {
    DebugLensPrefType.boolean => 'bool',
    DebugLensPrefType.integer => 'int',
    DebugLensPrefType.double => 'double',
    DebugLensPrefType.string => 'String',
    DebugLensPrefType.stringList => 'List',
    DebugLensPrefType.unknown => '?',
  };
}

/// One SharedPreferences entry for display. [value] is the readable string
/// form; [type] carries the original type; [encrypted] marks entries stored
/// via encrypted prefs (flagged `*`).
@immutable
class DebugLensPrefEntry {
  /// The preference key, shown as the row title.
  final String key;

  /// The value in readable string form, whatever its original type.
  final String value;

  /// The value's original type, shown as the row's type chip.
  final DebugLensPrefType type;

  /// Whether this entry came from encrypted preferences. Marked `*` and its
  /// value hidden until revealed.
  final bool encrypted;

  /// Builds one entry for the Storage screen's SharedPrefs tab.
  const DebugLensPrefEntry({
    required this.key,
    required this.value,
    this.type = DebugLensPrefType.unknown,
    this.encrypted = false,
  });
}
