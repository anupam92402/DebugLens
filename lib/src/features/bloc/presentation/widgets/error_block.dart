import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Red "ERROR" section header + the error text below it. Used when the
/// underlying bloc threw an uncaught exception.
class ErrorBlock extends StatelessWidget {
  final String error;

  const ErrorBlock({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          DebugStrings.commonErrorHeader,
          style: monoStyle(
            size: 11,
            weight: FontWeight.w700,
            color: DebugColors.error,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          error,
          style: monoStyle(size: 12, color: DebugColors.error),
        ),
      ],
    );
  }
}
