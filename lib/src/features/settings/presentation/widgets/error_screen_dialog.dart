import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Shows how to install `CustomErrorScreen`, with the one line to copy.
///
/// Read-only on purpose: DebugLens can't install `ErrorWidget.builder` itself
/// without taking over the host's error handling, so this documents the hook
/// rather than pretending to be a setting.
Future<void> showErrorScreenDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ErrorScreenDialog(),
  );
}

class _ErrorScreenDialog extends StatelessWidget {
  const _ErrorScreenDialog();

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(
      const ClipboardData(text: DebugStrings.errorScreenSetupSnippet),
    );
    if (!context.mounted) return;
    DebugToast.show(
      context,
      DebugStrings.commonFieldCopied(DebugStrings.errorScreenSetupCopyLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DebugColors.surface,
      title: Text(
        DebugStrings.errorScreenSetupTitle,
        style: monoStyle(size: 14),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DebugStrings.errorScreenSetupBody,
            style: monoStyle(size: 12, color: DebugColors.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                DebugStrings.errorScreenSetupHeader,
                style: monoStyle(
                  size: 11,
                  weight: FontWeight.w700,
                  color: DebugColors.textMuted,
                ),
              ),
              const Spacer(),
              CopyIcon(
                tooltip: DebugStrings.commonCopyField(
                  DebugStrings.errorScreenSetupCopyLabel,
                ),
                onTap: () => _copy(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const CodeBlock(
            DebugStrings.errorScreenSetupSnippet,
            color: DebugColors.textPrimary,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(DebugStrings.serviceOk),
        ),
      ],
    );
  }
}
