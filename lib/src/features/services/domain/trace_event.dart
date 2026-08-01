import 'package:flutter/foundation.dart';

/// One finished performance trace pushed in by the host's performance wrapper.
@immutable
class DebugLensTraceEvent {
  /// The trace name — `app_start`, `home_load`, … Shown as the row title.
  final String name;

  /// How long the traced work took, shown in the row's second line.
  final Duration duration;

  /// The trace's metrics and attributes flattened into one map — DebugLens
  /// draws no distinction between them. Shown as the row's fields when it is
  /// expanded. Copied on construction, so later mutation of the caller's map
  /// doesn't rewrite an already-recorded trace.
  final Map<String, Object?> attributes;

  /// Stamped by DebugLens when the trace is recorded.
  final DateTime time;

  DebugLensTraceEvent({
    required this.name,
    required this.duration,
    Map<String, Object?> attributes = const {},
    DateTime? time,
  }) : attributes = Map.unmodifiable(attributes),
       time = time ?? DateTime.now();
}
