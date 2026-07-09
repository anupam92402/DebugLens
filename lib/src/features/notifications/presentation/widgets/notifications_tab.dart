import 'package:flutter/material.dart';

import '../../domain/notification_entry.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'notification_tile.dart';

/// Push / local notification feed. Stateless because the parent screen
/// already watches the store and rebuilds when [items] changes.
class NotificationsTab extends StatelessWidget {
  final List<NotificationEntry> items;

  const NotificationsTab({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_off,
        message: DebugStrings.notificationsEmpty,
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: DebugPalette.border),
      itemBuilder: (_, i) => NotificationTile(entry: items[i]),
    );
  }
}
