import 'package:flutter/material.dart';
import '../../domain/notification_entry.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/json_view.dart';

class NotificationTile extends StatelessWidget {
  final NotificationEntry entry;

  const NotificationTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.notifications_outlined),
      title: Text(
        entry.title ?? DebugStrings.notificationsNoTitle,
        style: monoStyle(size: 13),
      ),
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
