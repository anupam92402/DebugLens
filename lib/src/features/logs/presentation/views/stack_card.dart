import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Card holding the log's stack trace in a code-style container.
class StackCard extends StatelessWidget {
  final String stackTrace;

  const StackCard({super.key, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: DebugStrings.logsStackCard,
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
