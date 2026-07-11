import 'package:flutter/material.dart';

import '../../../../shared/widgets/debug_widgets.dart';

/// Header above a navigator's stack when multiple navigators are tracked.
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
