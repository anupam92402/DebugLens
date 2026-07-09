import 'package:flutter/material.dart';

import '../../../core/debug_lens_logger.dart';
import '../../theme/debug_theme.dart';
import '../debug_widgets.dart';

/// One row in the Logs list. Console-sourced rows are visually distinct —
/// purple "C" badge, purple-tinted message — so they pop in a mixed feed
/// even when the level filter is open.
class LogTile extends StatelessWidget {
  final DebugLogRecord record;
  final VoidCallback onTap;

  const LogTile({
    super.key,
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isConsole = record.source == DebugLogSource.console;
    final tone =
        isConsole ? DebugPalette.console : toneForLevel(record.level);
    final label = record.name ?? (isConsole ? 'console' : 'log');
    // Console rows show a 'C' badge so they're distinguishable from custom
    // debug-level rows (which show 'D').
    final badge = isConsole ? 'C' : record.levelLabel;

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
              child: _MessageAndTag(
                record: record,
                isConsole: isConsole,
                label: label,
              ),
            ),
            const Icon(Icons.chevron_right, color: DebugPalette.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Two-line block — message on top, "[label] · time" below. Pulled out so
/// the tinting logic for console rows is colocated with the rendering.
class _MessageAndTag extends StatelessWidget {
  final DebugLogRecord record;
  final bool isConsole;
  final String label;

  const _MessageAndTag({
    required this.record,
    required this.isConsole,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          record.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: monoStyle(
            size: 13,
            color: isConsole ? DebugPalette.console : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '[$label] · ${formatClock(record.time)}',
          style: monoStyle(size: 11, color: DebugPalette.textMuted),
        ),
      ],
    );
  }
}
