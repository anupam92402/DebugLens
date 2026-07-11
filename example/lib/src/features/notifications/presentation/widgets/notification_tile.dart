import 'package:flutter/material.dart';

import '../../domain/app_notification.dart';

/// One notification row with a type-tinted icon and unread dot.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification});

  final AppNotification notification;

  static const _typeColors = {
    NotificationType.info: Color(0xFF4F46E5),
    NotificationType.success: Color(0xFF059669),
    NotificationType.alert: Color(0xFFD97706),
  };

  static const _typeIcons = {
    NotificationType.info: Icons.info_outline_rounded,
    NotificationType.success: Icons.check_circle_outline_rounded,
    NotificationType.alert: Icons.warning_amber_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _typeColors[notification.type]!;
    return Card(
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(_typeIcons[notification.type], color: color, size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.unread ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${notification.body}\n${notification.timeLabel}',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
        isThreeLine: true,
        trailing: notification.unread
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}
