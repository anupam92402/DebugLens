import 'package:flutter/material.dart';

import '../../domain/log_record.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'message_and_tag.dart';
import '../../../../shared/theme/debug_colors.dart';

/// One row in the Logs list: a level badge, the message, and its tag + time.
class LogTile extends StatelessWidget {
  final DebugLogRecord record;
  final VoidCallback onTap;

  const LogTile({super.key, required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(
              record.levelLabel,
              color: toneForLevel(record.level),
              filled: true,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MessageAndTag(
                record: record,
                label: record.name ?? DebugStrings.logsLog,
              ),
            ),
            const Icon(Icons.chevron_right, color: DebugColors.textMuted),
          ],
        ),
      ),
    );
  }
}
