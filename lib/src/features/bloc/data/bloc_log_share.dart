import 'dart:ui' show Rect;

import '../../../core/debug_log_file_service.dart';
import '../../../core/debug_store.dart';
import '../../../shared/debug_strings.dart';
import 'bloc_log_serializer.dart';

/// Builds the bloc section and shares it as a log file (`bloc_logs`).
class BlocLogShare {
  BlocLogShare._();

  static Future<void> share(DebugStore store, {Rect? origin}) async {
    DebugLogFileService.instance.setSection(
      'bloc',
      BlocLogSerializer.dump(store.blocEvents),
    );
    await DebugLogFileService.instance.shareLogFile(
      name: 'bloc_logs',
      subject: DebugStrings.blocShareSubject,
      sharePositionOrigin: origin,
    );
  }
}
