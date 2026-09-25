import '../../../shared/debug_strings.dart';

/// The level a log was recorded at. Deliberately a small three-tier scheme —
/// most app loggers map onto `info` / `error` / `debug` without loss.
enum DebugLogLevel {
  /// Something worth noting in the normal course of events.
  info,

  /// Something went wrong; usually carries an error and a stack trace.
  error,

  /// Detail useful while debugging, and noisy otherwise.
  debug;

  /// Uppercase and padded to a fixed width, so console lines and exported
  /// files line up in columns whatever the level.
  String get paddedName => name.toUpperCase().padRight(5);
}

/// A single immutable log record displayed by the Logs screen.
class DebugLogRecord {
  /// The level this record was logged at.
  final DebugLogLevel level;

  /// The message itself, clamped to DebugLens's per-record size ceiling.
  final String message;

  /// The `name` the caller passed, shown as the row's `[tag]` and matched by
  /// the screen's search. Null when the caller passed none.
  final String? name;

  /// The error that went with the record, kept as text rather than as the
  /// thrown object so the record can't pin the app's object graph.
  final Object? error;

  /// Where [error] was thrown, as text. Null when no stack trace was passed.
  final String? stackTrace;

  /// When the record was created.
  final DateTime time;

  /// Builds a record. The logger fills this in; hosts call `DebugLensLogger`'s
  /// `i` / `d` / `e` instead.
  const DebugLogRecord({
    required this.level,
    required this.message,
    required this.time,
    this.name,
    this.error,
    this.stackTrace,
  });

  /// Compact single-letter label used in chips and badges.
  String get levelLabel {
    switch (level) {
      case DebugLogLevel.info:
        return DebugStrings.logsLevelInfoBadge;
      case DebugLogLevel.error:
        return DebugStrings.logsLevelErrorBadge;
      case DebugLogLevel.debug:
        return DebugStrings.logsLevelDebugBadge;
    }
  }
}
