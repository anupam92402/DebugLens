import 'package:flutter/foundation.dart';

/// One crash / non-fatal report pushed in by the host's crash reporter.
@immutable
class DebugLensCrashEvent {
  /// The thrown object, rendered through `toString()`. Also the report's row
  /// title.
  final Object error;

  /// Where [error] was thrown, rendered as its own field on the report. Null
  /// when the host recorded the error without one — a `catch (e)` with no
  /// stack parameter, or an error surfaced from outside a zone.
  final StackTrace? stackTrace;

  /// Whether this was an unrecoverable crash rather than a logged-and-continued
  /// error. Drives the `fatal` / `non-fatal` marker on the row.
  final bool fatal;

  /// Why the error was recorded — Crashlytics' `reason`.
  final String? reason;

  /// Custom keys attached to the report. Copied on construction, so later
  /// mutation of the caller's map doesn't rewrite a recorded event.
  final Map<String, Object?> customData;

  /// Extra context lines attached to the report — breadcrumbs, recent logs,
  /// whatever the host wants to carry along. Stringified on construction so the
  /// event holds text, not a pinned reference to the app's object graph.
  final List<String> information;

  /// When the event was recorded. Defaults to now; pass it only when replaying
  /// something that happened earlier (a crash caught on the previous run).
  final DateTime time;

  DebugLensCrashEvent({
    required this.error,
    this.stackTrace,
    this.fatal = false,
    this.reason,
    Map<String, Object?> customData = const {},
    Iterable<Object> information = const [],
    DateTime? time,
  }) : customData = Map.unmodifiable(customData),
       information = List.unmodifiable([for (final i in information) '$i']),
       time = time ?? DateTime.now();
}
