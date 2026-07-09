import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/sequence_badge.dart';

/// One route in a navigator's live stack — level-numbered badge, route name,
/// and a "current" chip for the top of stack.
class StackRow extends StatelessWidget {
  final int level;
  final String routeName;
  final bool isCurrent;
  final Color accent;

  const StackRow({
    super.key,
    required this.level,
    required this.routeName,
    required this.isCurrent,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SequenceBadge('$level'),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              routeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(size: 13),
            ),
          ),
          if (isCurrent)
            StatusChip(
              DebugStrings.navigationCurrent,
              color: accent,
              filled: true,
            ),
        ],
      ),
    );
  }
}
