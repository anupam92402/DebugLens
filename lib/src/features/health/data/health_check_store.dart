import 'package:flutter/foundation.dart';

import '../../../shared/debug_constants.dart';
import '../../../shared/debug_strings.dart';
import '../../logs/data/debug_lens_logger.dart';
import '../../logs/domain/log_record.dart';
import '../../services/data/debug_crash_store.dart';
import '../domain/health_report.dart';

/// Runs the health check: a window opened by one tap and closed by the next,
/// reporting everything that failed in between.
///
/// **Session-only, and deliberately not persisted.** A check is a "watch what
/// happens while I do this" tool — carrying a half-open window across a
/// relaunch would report against a process that no longer exists. Closing the
/// app abandons it.
///
/// The sources are read at [stop], not sampled as they arrive, so clearing the
/// logs or the crash store mid-window removes those records from the report
/// too. That is the honest answer: the report says what is still there.
class HealthCheckStore extends ChangeNotifier {
  HealthCheckStore._();

  static final HealthCheckStore instance = HealthCheckStore._();

  DateTime? _startedAt;

  final List<HealthReport> _reports = <HealthReport>[];

  /// Never reset while the app lives, so numbers stay unique even after the
  /// oldest reports are trimmed.
  int _sequence = 0;

  /// Finished reports, newest first — session-only like the window itself, and
  /// capped at [DebugConstants.maxHealthReports].
  List<HealthReport> get reports => List.unmodifiable(_reports);

  bool get hasReports => _reports.isNotEmpty;

  /// When the current window opened, or null when no check is running.
  DateTime? get startedAt => _startedAt;

  bool get isRunning => _startedAt != null;

  /// Opens a window. No-op while one is already running.
  void start() {
    if (isRunning) return;
    _startedAt = DateTime.now();
    notifyListeners();
  }

  /// Closes the window and returns what fell inside it, newest first.
  ///
  /// Returns null when no check is running, so a caller can't build a report
  /// out of nothing.
  HealthReport? stop() {
    final startedAt = _startedAt;
    if (startedAt == null) return null;
    final stoppedAt = DateTime.now();
    _startedAt = null;
    notifyListeners();

    final entries = [..._crashes(startedAt), ..._errorLogs(startedAt)]
      ..sort((a, b) => b.time.compareTo(a.time));
    _sequence++;
    final report = HealthReport(
      number: _sequence,
      startedAt: startedAt,
      stoppedAt: stoppedAt,
      entries: entries,
    );
    _reports.insert(0, report);
    if (_reports.length > DebugConstants.maxHealthReports) {
      _reports.removeLast();
    }
    return report;
  }

  /// Abandons the window without producing a report.
  void cancel() {
    if (!isRunning) return;
    _startedAt = null;
    notifyListeners();
  }

  Iterable<HealthEntry> _crashes(DateTime since) sync* {
    for (final event in DebugCrashStore.instance.events) {
      if (event.time.isBefore(since)) continue;
      yield HealthEntry(
        kind: HealthEntryKind.crash,
        title: '${event.error}',
        subtitle: event.fatal
            ? DebugStrings.crashFatal
            : DebugStrings.crashNonFatal,
        detail: event.reason,
        stackTrace: event.stackTrace?.toString(),
        time: event.time,
      );
    }
  }

  Iterable<HealthEntry> _errorLogs(DateTime since) sync* {
    for (final record in DebugLensLogger.instance.history) {
      if (record.level != DebugLogLevel.error) continue;
      if (record.time.isBefore(since)) continue;
      yield HealthEntry(
        kind: HealthEntryKind.log,
        title: record.message,
        subtitle: record.name,
        detail: record.error?.toString(),
        stackTrace: record.stackTrace,
        time: record.time,
      );
    }
  }
}
