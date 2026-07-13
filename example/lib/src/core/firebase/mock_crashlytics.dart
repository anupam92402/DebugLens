import 'package:flutter/foundation.dart';

/// A recorded error, mirroring `FirebaseCrashlytics.recordError`.
@immutable
class MockCrashReport {
  final String message;
  final String? stack;
  final bool fatal;
  final DateTime time;

  const MockCrashReport({
    required this.message,
    required this.fatal,
    required this.time,
    this.stack,
  });
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
  final List<String> breadcrumbs = [];

  /// Recorded errors, newest-first.
  final List<MockCrashReport> reports = [];

  final Map<String, String> customKeys = {};
  String? userIdentifier;

  void log(String message) {
    breadcrumbs.insert(0, message);
    if (breadcrumbs.length > _maxBreadcrumbs) breadcrumbs.removeLast();
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
        message: reason != null ? '$reason — $error' : '$error',
        stack: stack?.toString(),
        fatal: fatal,
        time: DateTime.now(),
      ),
    );
    if (reports.length > _maxReports) reports.removeLast();
  }
}
