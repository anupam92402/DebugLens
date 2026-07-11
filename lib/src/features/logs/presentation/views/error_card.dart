import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Card showing the attached error object on the log detail screen.
class ErrorCard extends StatelessWidget {
  final Object error;

  const ErrorCard({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: DebugStrings.logsErrorCard,
      child: SelectableText(
        error.toString(),
        style: monoStyle(size: 13, color: DebugColors.error),
      ),
    );
  }
}
