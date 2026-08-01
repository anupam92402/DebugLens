import 'package:flutter/foundation.dart';

/// One analytics event pushed in by the host's analytics wrapper.
@immutable
class DebugLensAnalyticsEvent {
  /// The event name — `screen_view`, `add_to_cart`, … Shown as the row title.
  final String name;

  /// Everything else the event carries, shown as the row's fields when it is
  /// expanded. Copied on construction, so later mutation of the caller's map
  /// doesn't rewrite an already-recorded event.
  final Map<String, Object?> parameters;

  /// Stamped by DebugLens when the event is recorded, and shown as the row's
  /// second line under the name.
  final DateTime time;

  DebugLensAnalyticsEvent({
    required this.name,
    Map<String, Object?> parameters = const {},
    DateTime? time,
  }) : parameters = Map.unmodifiable(parameters),
       time = time ?? DateTime.now();
}
