import 'package:flutter/material.dart';

import '../debug_strings.dart';

/// Icon button that flips a list's sort order. Defaults to the common
/// newest/oldest tooltips; pass custom ones for other orderings.
class SortToggle extends StatelessWidget {
  const SortToggle({
    super.key,
    required this.newestFirst,
    required this.onToggle,
    this.newestTooltip = DebugStrings.commonSortNewest,
    this.oldestTooltip = DebugStrings.commonSortOldest,
  });

  final bool newestFirst;
  final VoidCallback onToggle;
  final String newestTooltip;
  final String oldestTooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: newestFirst ? newestTooltip : oldestTooltip,
      icon: const Icon(Icons.swap_vert),
      onPressed: onToggle,
    );
  }
}
