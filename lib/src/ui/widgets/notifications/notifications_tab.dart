import 'package:flutter/material.dart';

import '../../../core/models/notification_entry.dart';
import '../../theme/debug_theme.dart';
import '../debug_widgets.dart';
import '../json_view.dart';

/// Push / local notification feed. Stateless because the parent screen
/// already watches the store and rebuilds when [items] changes.
class NotificationsTab extends StatelessWidget {
  final List<NotificationEntry> items;

  const NotificationsTab({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
          icon: Icons.notifications_off, message: 'No notifications');
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: DebugPalette.border),
      itemBuilder: (_, i) => _NotificationTile(entry: items[i]),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationEntry entry;

  const _NotificationTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.notifications_outlined),
      title:
          Text(entry.title ?? '(no title)', style: monoStyle(size: 13)),
      subtitle: Text(
        '${entry.source} · ${entry.kindLabel} · ${formatClock(entry.time)}',
        style: monoStyle(size: 11, color: DebugPalette.textMuted),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        if (entry.body != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(entry.body!, style: monoStyle(size: 12)),
            ),
          ),
        JsonView(entry.payload),
      ],
    );
  }
}
