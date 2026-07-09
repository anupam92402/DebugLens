import 'package:flutter/material.dart';

import '../../../../shared/widgets/debug_widgets.dart';

/// Section header shown above a navigator's stack when more than one
/// navigator is tracked (nested-navigator case).
class StackSectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const StackSectionHeader({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
      child: Text(
        label.toUpperCase(),
        style: monoStyle(size: 11, weight: FontWeight.w700, color: color),
      ),
    );
  }
}
