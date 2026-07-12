import 'package:flutter/foundation.dart';

/// The original type of a SharedPreferences value, so the Storage screen can
/// show a type label even though [DebugLensPrefEntry.value] is a string.
enum DebugLensPrefType {
  boolean,
  integer,
  double,
  string,
  stringList,
  unknown;

  /// Short label shown as the type chip.
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
  final String key;
  final String value;
  final DebugLensPrefType type;
  final bool encrypted;

  const DebugLensPrefEntry({
    required this.key,
    required this.value,
    this.type = DebugLensPrefType.unknown,
    this.encrypted = false,
  });
}
