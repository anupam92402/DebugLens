import 'package:flutter/foundation.dart';

/// Where a health-check entry came from.
enum HealthEntryKind { crash, log }

/// One thing that went wrong inside a health-check window.
@immutable
class HealthEntry {
  final HealthEntryKind kind;

  /// Row title: the error for a crash, the message for a log.
  final String title;

  /// Second line — severity for a crash, logger name for a log.
  final String? subtitle;

  /// Extra context shown when the row expands: a crash's reason, a log's error.
  final String? detail;

  final String? stackTrace;

  final DateTime time;

  const HealthEntry({
    required this.kind,
    required this.title,
    required this.time,
    this.subtitle,
    this.detail,
    this.stackTrace,
  });
}

/// What a health check found between its start and stop taps.
@immutable
class HealthReport {
  /// 1-based position in the session's run of checks. Stamped when the report
  /// is made rather than derived from the list, so trimming old reports never
  /// renumbers the ones that remain.
  final int number;

  final DateTime startedAt;
  final DateTime stoppedAt;

  /// Crashes and error logs interleaved, newest first.
  final List<HealthEntry> entries;

  const HealthReport({
    required this.number,
    required this.startedAt,
    required this.stoppedAt,
    required this.entries,
  });

  Duration get duration => stoppedAt.difference(startedAt);

  int get crashCount =>
      entries.where((e) => e.kind == HealthEntryKind.crash).length;

  int get logCount =>
      entries.where((e) => e.kind == HealthEntryKind.log).length;

  bool get isClean => entries.isEmpty;
}
