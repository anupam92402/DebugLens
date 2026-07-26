import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Card holding the log's stack trace in a code-style container, with a
/// one-tap copy in its header — the block you most often paste into a ticket.
class StackCard extends StatelessWidget {
  final String stackTrace;

  const StackCard({super.key, required this.stackTrace});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: stackTrace));
    DebugToast.show(
      context,
      DebugStrings.commonFieldCopied(DebugStrings.logsStackCard),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: DebugStrings.logsStackCard,
      onCopy: () => _copy(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DebugColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SelectableText(
          stackTrace,
          style: monoStyle(size: 12, color: DebugColors.textMuted),
        ),
      ),
    );
  }
}
