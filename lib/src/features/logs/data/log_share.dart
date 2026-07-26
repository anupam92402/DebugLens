import 'dart:ui' show Rect;

import '../../../core/debug_log_file_service.dart';
import '../../../shared/debug_strings.dart';
import '../domain/log_record.dart';
import 'log_serializer.dart';

/// Builds the logs section and shares it as a log file (`logs`).
class LogShare {
  LogShare._();

  static Future<void> share(
    List<DebugLogRecord> records, {
    Rect? origin,
  }) async {
    DebugLogFileService.instance.setSection(
      'logs',
      LogSerializer.formatBundle(records),
    );
    await DebugLogFileService.instance.shareLogFile(
      name: 'logs',
      subject: DebugStrings.logsShareSubject,
      sharePositionOrigin: origin,
    );
  }
}
