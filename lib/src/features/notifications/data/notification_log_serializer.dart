import 'dart:convert';

import '../../../shared/util/clock_format.dart';
import '../domain/notification_entry.dart';
import '../domain/deeplink_entry.dart';

/// Formats captured notifications / deep-links into plain-text share sections.
class NotificationLogSerializer {
  NotificationLogSerializer._();

  static String dumpNotifications(List<NotificationEntry> items) {
    final b = StringBuffer()..writeln('Notifications (${items.length}):');
    for (final e in items) {
      b.writeln(
        '[${e.source}] ${e.kindLabel} ${ClockFormat.clock(e.time)} '
        '${e.title ?? ''} — ${e.body ?? ''}',
      );
      if (e.payload.isNotEmpty) {
        b.writeln('  payload: ${jsonEncode(e.payload)}');
      }
    }
    return b.toString().trimRight();
  }

  static String dumpDeeplinks(List<DeeplinkEntry> items) {
    final b = StringBuffer()..writeln('Deeplinks (${items.length}):');
    for (final e in items) {
      b.writeln('[${e.source ?? ''}] ${ClockFormat.clock(e.time)} ${e.uri}');
    }
    return b.toString().trimRight();
  }
}
