import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Card holding the log's message text, with a one-tap copy in its header.
class MessageCard extends StatelessWidget {
  final String message;

  const MessageCard({super.key, required this.message});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message));
    DebugToast.show(
      context,
      DebugStrings.commonFieldCopied(DebugStrings.logsMessageCard),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: DebugStrings.logsMessageCard,
      onCopy: () => _copy(context),
      child: SelectableText(message, style: monoStyle(size: 13)),
    );
  }
}
