import 'package:flutter/foundation.dart';

/// One finished performance trace pushed in by the host's performance wrapper.
///
/// Only *finished* traces reach DebugLens. The host keeps owning the running
/// trace — the stopwatch, and the metrics and attributes accumulating on it —
/// and pushes once when it stops, so there is no start/stop protocol here and
/// no way for a half-recorded trace to sit in the panel.
///
/// Internal — hosts push through `DebugLens.instance.recordTrace`, which builds
/// this, so there is nothing here for a caller to construct.
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
