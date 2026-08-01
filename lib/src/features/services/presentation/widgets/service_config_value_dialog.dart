import 'package:flutter/material.dart';

import '../../domain/config_editor.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/util/copy_share.dart';
import 'config_value_block.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Shows [entry] read-only — the counterpart to `showConfigEditDialog` for a
/// service showing its source of truth, where a value can be inspected and
/// copied but not changed.
Future<void> showConfigValueDialog(
  BuildContext context,
  DebugLensConfigEntry entry,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ConfigValueDialog(entry: entry),
  );
}

class _ConfigValueDialog extends StatelessWidget {
  final DebugLensConfigEntry entry;

  const _ConfigValueDialog({required this.entry});

  @override
  Widget build(BuildContext context) {
    // The source value is only worth its own block when it differs from the
    // effective one — with no override in force they are the same string.
    final source = entry.sourceValue;
    final showSource = source != null && source != entry.value;

    return AlertDialog(
      backgroundColor: DebugColors.surface,
      scrollable: true,
      title: Row(
        children: [
          StatusChip(entry.type.label, color: toneForConfigType(entry.type)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.key,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(size: 14),
            ),
          ),
          if (entry.overridden)
            StatusChip(
              DebugStrings.serviceOverridden,
              color: DebugColors.service,
            ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConfigValueBlock(entry.value, color: DebugColors.textPrimary),
          if (showSource) ...[
            const SizedBox(height: 12),
            Text(
              DebugStrings.serviceSourceValueLabel,
              style: monoStyle(size: 11, color: DebugColors.textMuted),
            ),
            const SizedBox(height: 4),
            ConfigValueBlock(source),
          ],
        ],
      ),
      actions: [
        TextButton(
          // `key: value` with the effective value — what the app reads — not
          // the label or the source line.
          onPressed: () =>
              copyAndShare(context, entry.pair(), label: entry.key),
          child: Text(
            DebugStrings.commonCopy,
            style: monoStyle(size: 13, color: DebugColors.info),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(DebugStrings.commonClose, style: monoStyle(size: 13)),
        ),
      ],
    );
  }
}
