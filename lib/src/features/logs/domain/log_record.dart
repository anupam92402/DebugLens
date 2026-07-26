import '../../../shared/debug_strings.dart';

/// The level a log was recorded at. Deliberately a small three-tier scheme —
/// most app loggers map onto `info` / `error` / `debug` without loss.
enum DebugLogLevel {
  info,
  error,
  debug;

  /// Uppercase and padded to a fixed width, so console lines and exported
  /// files line up in columns whatever the level.
  String get paddedName => name.toUpperCase().padRight(5);
}

/// A single immutable log record displayed by the Logs screen.
class DebugLogRecord {
  final DebugLogLevel level;
  final String message;
  final String? name;
  final Object? error;
  final String? stackTrace;
  final DateTime time;

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
