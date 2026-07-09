import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/debug_store.dart';
import '../debug_widgets.dart';
import '../sequence_badge.dart';

/// Stack tab body — renders the live route stack(s) maintained by the
/// navigator observer(s). When more than one navigator is tracked
/// (nested-navigator case), each gets its own labeled section.
class NavStackTab extends StatelessWidget {
  const NavStackTab({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final stacks = context.watch<DebugStore>().navStacks;
    if (stacks.isEmpty) {
      return const EmptyState(
          icon: Icons.layers_clear, message: 'Stack is empty');
    }
    final showHeaders = stacks.length > 1;
    return ListView(
      children: [
        for (final entry in stacks.entries) ...[
          if (showHeaders) _StackSectionHeader(label: entry.key, color: accent),
          ..._stackRows(accent, entry.value),
        ],
      ],
    );
  }

  /// Builds the rows for one navigator's stack — top first, level-numbered.
  /// Pulled out so the section header + rows can be composed in build().
  List<Widget> _stackRows(Color accent, List<String> stack) {
    // top-of-stack first matches how a user thinks of "current screen"
    final display = stack.reversed.toList();
    return [
      for (var i = 0; i < display.length; i++)
        _StackRow(
          level: stack.length - i,
          routeName: display[i],
          isCurrent: i == 0,
          accent: accent,
        ),
    ];
  }
}

class _StackSectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _StackSectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
      child: Text(
        label.toUpperCase(),
        style:
            monoStyle(size: 11, weight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _StackRow extends StatelessWidget {
  final int level;
  final String routeName;
  final bool isCurrent;
  final Color accent;

  const _StackRow({
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
          if (isCurrent) StatusChip('current', color: accent, filled: true),
        ],
      ),
    );
  }
}
