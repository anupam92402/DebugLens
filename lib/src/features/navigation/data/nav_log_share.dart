import 'dart:ui' show Rect;

import '../../../core/debug_log_file_service.dart';
import '../../../core/debug_store.dart';
import '../../../shared/debug_strings.dart';
import 'nav_log_serializer.dart';

/// Builds the navigation section and shares it as a log file.
class NavLogShare {
  NavLogShare._();

  static Future<void> share(
    DebugStore store, {
    required bool hideDebugLens,
    Rect? origin,
  }) async {
    DebugLogFileService.instance.setSection(
      'navigation',
      NavLogSerializer.dump(
        store.navEvents,
        store.navStacks,
        hideDebugLens: hideDebugLens,
      ),
    );
    await DebugLogFileService.instance.shareLogFile(
      name: 'navigation_logs',
      subject: DebugStrings.navigationShareSubject,
      sharePositionOrigin: origin,
    );
  }
}
