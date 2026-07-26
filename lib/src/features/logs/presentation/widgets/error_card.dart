import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Card showing the attached error object, with a one-tap copy in its header.
class ErrorCard extends StatelessWidget {
  final Object error;

  const ErrorCard({super.key, required this.error});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: error.toString()));
    DebugToast.show(
      context,
      DebugStrings.commonFieldCopied(DebugStrings.logsErrorCard),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: DebugStrings.logsErrorCard,
      onCopy: () => _copy(context),
      child: SelectableText(
        error.toString(),
        style: monoStyle(size: 13, color: DebugColors.error),
      ),
    );
  }
}
