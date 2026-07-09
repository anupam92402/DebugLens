import 'package:flutter/foundation.dart';

import '../domain/log_record.dart';

/// Optional external observer signature — mirrors WeLogger's so server-forward
/// code written against WeLogger keeps working.
typedef DebugLogObserver =
    void Function(
      String message,
      DebugLogLevel level, {
      String? name,
      Object? error,
      StackTrace? stackTrace,
    });

/// Singleton logger used by app code to emit logs that appear in DebugLens.
///
/// Mirrors the API of `WeLogger` from the team's `we_core` package so existing
/// call-sites translate directly:
///
/// ```dart
/// DebugLensLogger().i('Login succeeded', name: 'auth');
/// DebugLensLogger().e('Charge failed', name: 'payment', error: e, stackTrace: s);
/// DebugLensLogger().d('Frame built in 8ms');
/// ```
///
/// Extends [ChangeNotifier] so the Logs screen rebuilds automatically when a
/// record is appended.
class DebugLensLogger extends ChangeNotifier {
  DebugLensLogger._internal();

  static final DebugLensLogger _instance = DebugLensLogger._internal();

  /// Singleton accessor. The factory makes `DebugLensLogger()` and
  /// `DebugLensLogger.instance` interchangeable.
  factory DebugLensLogger() => _instance;

  /// Convenience alias matching the rest of the package's static accessors.
  static DebugLensLogger get instance => _instance;

  /// When `false`, calls produce neither console output nor observer
  /// callbacks (records are still appended to in-memory history so DebugLens
  /// always shows them). Defaults to `kDebugMode` to match WeLogger.
  bool showLogs = kDebugMode;

  /// Hard cap on retained records — oldest are dropped first.
  static const int _maxHistory = 1000;

  final List<DebugLogRecord> _history = [];
  final List<DebugLogObserver> _onLog = [];

  /// Read-only view of recorded logs (oldest first).
  List<DebugLogRecord> get history => List.unmodifiable(_history);

  /// Registers an external observer. Useful for shipping logs to a server.
  ///
  /// ```dart
  /// DebugLensLogger().setLogObserver((message, level, {name, error, stackTrace}) {
  ///   sendLogToServer(message, name, error, stackTrace);
  /// });
  /// ```
  ///
  /// Note:
  /// - Don't call [DebugLensLogger] methods inside the observer — it will
  ///   recurse forever (StackOverflow).
  /// - If running inside [runZonedGuarded], don't use `print` inside the
  ///   observer for the same reason.
  /// - Pair with [removeLogObserver] when the observer is no longer needed.
  void setLogObserver(DebugLogObserver onLog) => _onLog.add(onLog);

  /// Removes a previously registered observer. See [setLogObserver].
  void removeLogObserver(DebugLogObserver onLog) => _onLog.remove(onLog);

  /// Logs an info message.
  void i(String message, {String? name, bool force = false}) {
    _log(message, name: name, level: DebugLogLevel.info, force: force);
  }

  /// Logs an error message. Pass [error] / [stackTrace] for full context.
  void e(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    bool force = false,
  }) {
    _log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: DebugLogLevel.error,
      force: force,
    );
  }

  /// Logs a debug message.
  void d(String message, {String? name, bool force = false}) {
    _log(message, name: name, level: DebugLogLevel.debug, force: force);
  }

  /// Internal hook used by the console-capture wiring in `DebugLens.wrap()`
  /// to inject `debugPrint` / `print` lines as records. Not for app code.
  void recordConsole(String message) {
    _append(
      DebugLogRecord(
        level: DebugLogLevel.debug,
        source: DebugLogSource.console,
        message: message,
        time: DateTime.now(),
      ),
    );
  }

  /// Drops all retained records.
  void clear() {
    if (_history.isEmpty) return;
    _history.clear();
    notifyListeners();
  }

  void _log(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    required DebugLogLevel level,
    bool force = false,
  }) {
    final logBuffer = StringBuffer('Flutter-Log');
    if (name?.isNotEmpty ?? false) logBuffer.write('-$name');
    final logName = logBuffer.toString();

    // Records always land in history so DebugLens can show them, even when
    // console output / observers are disabled.
    _append(
      DebugLogRecord(
        level: level,
        message: message,
        name: name,
        error: error,
        stackTrace: stackTrace?.toString(),
        time: DateTime.now(),
      ),
    );

    if (showLogs || force) {
      final messageBuffer = StringBuffer()..write('[$logName] $message');
      if (error != null) messageBuffer.write('\nError: $error');
      if (stackTrace != null) messageBuffer.write('\nStackTrace: $stackTrace');

      _printColored(
        messageBuffer.toString(),
        level == DebugLogLevel.info
            ? _ansiGreen
            : level == DebugLogLevel.error
            ? _ansiRed
            : _ansiBlue,
      );

      for (final observer in _onLog) {
        observer.call(
          message,
          level,
          name: logName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  void _append(DebugLogRecord record) {
    _history.add(record);
    if (_history.length > _maxHistory) _history.removeAt(0);
    notifyListeners();
  }

  /// Prints text in chunks to avoid the ~1KB truncation Flutter applies to
  /// long console lines. See:
  /// https://github.com/flutter/flutter/issues/22665#issuecomment-458186456
  ///
  /// Splits on newlines *first* so a stack-trace frame is never broken across
  /// chunks — only individual lines longer than [chunkSize] are subdivided.
  /// Uses raw [print] rather than [debugPrint] so the console-capture override
  /// installed by `DebugLens.wrap()` (which hooks [debugPrint]) can't recurse
  /// back into the logger.
  void _printColored(String text, String colorCode) {
    const chunkSize = 800;
    for (final line in text.split('\n')) {
      if (line.length <= chunkSize) {
        // ignore: avoid_print
        print('$colorCode$line$_ansiReset');
      } else {
        for (var i = 0; i < line.length; i += chunkSize) {
          final end = (i + chunkSize < line.length)
              ? i + chunkSize
              : line.length;
          // ignore: avoid_print
          print('$colorCode${line.substring(i, end)}$_ansiReset');
        }
      }
    }
  }
}

// ANSI escape codes for coloring console output.
const String _ansiBlue = '\x1B[34m';
const String _ansiGreen = '\x1B[32m';
const String _ansiRed = '\x1B[31m';
const String _ansiReset = '\x1B[0m';
