import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Confirms wiping every captured feed. Resolves to true to proceed, and to
/// false or null on cancel or dismiss.
///
/// The only destructive action in the panel, and the only one that can't be
/// undone — captured data isn't persisted anywhere to restore it from. The
/// message spells out what goes and what stays, since "all data" reads wider
/// than it is: settings and overrides survive.
Future<bool?> showClearDataDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: DebugColors.surface,
      title: Text(DebugStrings.settingsClearAll, style: monoStyle(size: 14)),
      content: Text(
        DebugStrings.settingsClearConfirm,
        style: monoStyle(size: 12, color: DebugColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(DebugStrings.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            DebugStrings.settingsClearAction,
            style: const TextStyle(color: DebugColors.error),
          ),
        ),
      ],
    ),
  );
}
