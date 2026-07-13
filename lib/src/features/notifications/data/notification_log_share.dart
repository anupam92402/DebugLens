import 'dart:ui' show Rect;

import '../../../core/debug_log_file_service.dart';
import '../../../core/debug_store.dart';
import '../../../shared/debug_strings.dart';
import 'notification_log_serializer.dart';

/// Builds a notifications / deep-links section and shares it as a log file.
class NotificationLogShare {
  NotificationLogShare._();

  static Future<void> shareNotifications(DebugStore store, {Rect? origin}) {
    DebugLogFileService.instance.setSection(
      'notifications',
      NotificationLogSerializer.dumpNotifications(store.notifications),
    );
    return DebugLogFileService.instance.shareLogFile(
      name: 'notifications_logs',
      subject: DebugStrings.notificationsShareSubject,
      sharePositionOrigin: origin,
    );
  }

  static Future<void> shareDeeplinks(DebugStore store, {Rect? origin}) {
    DebugLogFileService.instance.setSection(
      'deeplinks',
      NotificationLogSerializer.dumpDeeplinks(store.deeplinks),
    );
    return DebugLogFileService.instance.shareLogFile(
      name: 'deeplinks_logs',
      subject: DebugStrings.deeplinksShareSubject,
      sharePositionOrigin: origin,
    );
  }
}
