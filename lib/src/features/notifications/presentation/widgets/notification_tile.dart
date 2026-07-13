import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/notification_entry.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/json_view.dart';
import '../../../../shared/theme/debug_colors.dart';

class NotificationTile extends StatelessWidget {
  final NotificationEntry entry;

  const NotificationTile({super.key, required this.entry});

  void _copy(BuildContext context) {
    final b = StringBuffer()
      ..writeln(entry.title ?? DebugStrings.notificationsNoTitle);
    if (entry.body != null) b.writeln(entry.body);
    b.writeln(
      '${entry.source} · ${entry.kindLabel} · ${ClockFormat.clock(entry.time)}',
    );
    if (entry.payload.isNotEmpty) b.write(jsonEncode(entry.payload));
    Clipboard.setData(ClipboardData(text: b.toString().trimRight()));
    DebugToast.show(context, DebugStrings.notificationsCopiedToast);
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.notifications_outlined),
      title: Row(
        children: [
          Expanded(
            child: Text(
              entry.title ?? DebugStrings.notificationsNoTitle,
              style: monoStyle(size: 13),
            ),
          ),
          CopyIcon(
            tooltip: DebugStrings.notificationsCopy,
            onTap: () => _copy(context),
          ),
        ],
      ),
      subtitle: Text(
        '${entry.source} · ${entry.kindLabel} · ${ClockFormat.clock(entry.time)}',
        style: monoStyle(size: 11, color: DebugColors.textMuted),
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
