import 'dart:ui' show Rect;

import '../../../core/debug_log_file_service.dart';
import '../../../shared/debug_strings.dart';
import '../../../shared/util/clock_format.dart';
import '../domain/health_report.dart';

/// Serializes a [HealthReport] and shares it as a log file.
class HealthLogShare {
  HealthLogShare._();

  static Future<void> share(HealthReport report, {Rect? origin}) async {
    DebugLogFileService.instance.setSection('health', dump(report));
    await DebugLogFileService.instance.shareLogFile(
      name: 'health_check',
      subject: DebugStrings.healthShareSubject,
      sharePositionOrigin: origin,
    );
  }

  /// Plain-text report: the window, the tally, then one block per entry.
  static String dump(HealthReport report) {
    final b = StringBuffer()
      ..writeln(DebugStrings.healthTitleNumbered(report.number))
      ..writeln(
        '${ClockFormat.dateTime(report.startedAt)} → '
        '${ClockFormat.dateTime(report.stoppedAt)} '
        '(${ClockFormat.gap(report.duration)})',
      )
      ..writeln('${report.crashCount} crashes · ${report.logCount} error logs');
    for (final entry in report.entries) {
      b
        ..writeln()
        ..writeln(
          '[${entry.kind.name.toUpperCase()}] '
          '${ClockFormat.clock(entry.time)}  ${entry.title}',
        );
      if (entry.subtitle != null) b.writeln('  ${entry.subtitle}');
      if (entry.detail != null) b.writeln('  ${entry.detail}');
      if (entry.stackTrace != null) b.writeln(entry.stackTrace);
    }
    return b.toString().trimRight();
  }
}
