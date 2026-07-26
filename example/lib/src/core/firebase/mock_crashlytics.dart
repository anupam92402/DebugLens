import 'package:flutter/foundation.dart';

/// A recorded error, mirroring `FirebaseCrashlytics.recordError`.
@immutable
class MockCrashReport {
  final String message;
  final String? reason;
  final String? stack;
  final bool fatal;
  final DateTime time;

  const MockCrashReport({
    required this.message,
    required this.fatal,
    required this.time,
    this.reason,
    this.stack,
  });
}

/// A single breadcrumb log line with its timestamp.
@immutable
class MockBreadcrumb {
  final String message;
  final DateTime time;

  const MockBreadcrumb(this.message, this.time);
}

/// In-memory stand-in for `FirebaseCrashlytics`. Keeps breadcrumb logs, custom
/// keys, the user identifier and recorded (non-)fatal errors so the DebugLens
/// Firebase inspector can render them. Pure Dart — nothing is uploaded.
class MockCrashlytics {
  MockCrashlytics._();
  static final MockCrashlytics instance = MockCrashlytics._();

  static const int _maxBreadcrumbs = 50;
  static const int _maxReports = 50;

  /// Breadcrumb log, newest-first.
  final List<MockBreadcrumb> breadcrumbs = [];

  /// Recorded errors, newest-first.
  final List<MockCrashReport> reports = [];

  final Map<String, String> customKeys = {};
  String? userIdentifier;

  /// Per-install identifier, like Crashlytics' installation id. Surfaced to the
  /// inspector as a *sensitive* value so it stays masked and is redacted from
  /// shared log files.
  final String installId = 'fid-8f3c0b21-4d7e-42aa-9b16-77c5e0d31a94';

  /// Bumped whenever [reports] or [breadcrumbs] change — the service's DebugLens
  /// `changes` signal, so an open inspector re-pulls as errors are recorded.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void log(String message) {
    breadcrumbs.insert(0, MockBreadcrumb(message, DateTime.now()));
    if (breadcrumbs.length > _maxBreadcrumbs) breadcrumbs.removeLast();
    revision.value++;
  }

  void setCustomKey(String key, Object value) => customKeys[key] = '$value';

  void setUserIdentifier(String id) => userIdentifier = id;

  /// Records a caught error. [fatal] marks an unrecoverable crash; the default
  /// is a non-fatal (the common "log and continue" case).
  void recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    reports.insert(
      0,
      MockCrashReport(
        message: '$error',
        reason: reason,
        stack: stack?.toString(),
        fatal: fatal,
        time: DateTime.now(),
      ),
    );
    if (reports.length > _maxReports) reports.removeLast();
    revision.value++;
  }

  void clear() {
    reports.clear();
    breadcrumbs.clear();
    revision.value++;
  }
}
