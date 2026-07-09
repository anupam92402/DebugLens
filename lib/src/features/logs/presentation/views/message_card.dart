import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Card holding the log's message text on the log detail screen.
class MessageCard extends StatelessWidget {
  final String message;

  const MessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: DebugStrings.logsMessageCard,
      child: SelectableText(message, style: monoStyle(size: 13)),
    );
  }
}
