import 'package:flutter/material.dart';

import '../../domain/log_record.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'message_and_tag.dart';
import '../../../../shared/theme/debug_colors.dart';

/// One row in the Logs list. Console-sourced rows are visually distinct —
/// purple "C" badge, purple-tinted message — so they pop in a mixed feed
/// even when the level filter is open.
class LogTile extends StatelessWidget {
  final DebugLogRecord record;
  final VoidCallback onTap;

  const LogTile({super.key, required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isConsole = record.source == DebugLogSource.console;
    final tone = isConsole ? DebugColors.console : toneForLevel(record.level);
    final label =
        record.name ??
        (isConsole ? DebugStrings.logsConsole : DebugStrings.logsLog);
    // Console rows show a 'C' badge so they're distinguishable from custom
    // debug-level rows (which show 'D').
    final badge = isConsole ? DebugStrings.logsConsoleBadge : record.levelLabel;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(badge, color: tone, filled: true),
            const SizedBox(width: 10),
            Expanded(
              child: MessageAndTag(
                record: record,
                isConsole: isConsole,
                label: label,
              ),
            ),
            const Icon(Icons.chevron_right, color: DebugColors.textMuted),
          ],
        ),
      ),
    );
  }
}
