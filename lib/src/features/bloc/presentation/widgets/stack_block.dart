import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Muted "STACK" header + a code-style container with the stack trace.
/// Always paired with [ErrorBlock] in practice.
class StackBlock extends StatelessWidget {
  final String stackTrace;

  const StackBlock({super.key, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          DebugStrings.commonStackHeader,
          style: monoStyle(
            size: 11,
            weight: FontWeight.w700,
            color: DebugPalette.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DebugPalette.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            stackTrace,
            style: monoStyle(size: 12, color: DebugPalette.textMuted),
          ),
        ),
      ],
    );
  }
}
