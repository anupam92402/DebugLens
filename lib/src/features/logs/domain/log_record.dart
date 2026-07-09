/// The level a log was recorded at. Mirrors the three-tier scheme used by
/// the team's existing WeLogger so call-sites can swap in DebugLensLogger
/// with no semantic change.
enum DebugLogLevel { info, error, debug }

/// Where a log record came from.
///
/// * [custom] — produced by an explicit `DebugLensLogger` call.
/// * [console] — captured from `debugPrint` / `print` by the console hook.
enum DebugLogSource { custom, console }

/// A single immutable log record displayed by the Logs screen.
class DebugLogRecord {
  final DebugLogLevel level;
  final DebugLogSource source;
  final String message;
  final String? name;
  final Object? error;
  final String? stackTrace;
  final DateTime time;

  const DebugLogRecord({
    required this.level,
    required this.message,
    required this.time,
    this.source = DebugLogSource.custom,
    this.name,
    this.error,
    this.stackTrace,
  });

  /// Compact single-letter label used in chips and badges.
  String get levelLabel {
    switch (level) {
      case DebugLogLevel.info:
        return 'I';
      case DebugLogLevel.error:
        return 'E';
      case DebugLogLevel.debug:
        return 'D';
    }
  }
}
