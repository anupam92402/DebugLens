import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'stack_row.dart';
import 'stack_section_header.dart';

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
        icon: Icons.layers_clear,
        message: DebugStrings.navigationStackEmpty,
      );
    }
    final showHeaders = stacks.length > 1;
    return ListView(
      children: [
        for (final entry in stacks.entries) ...[
          if (showHeaders) StackSectionHeader(label: entry.key, color: accent),
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
        StackRow(
          level: stack.length - i,
          routeName: display[i],
          isCurrent: i == 0,
          accent: accent,
        ),
    ];
  }
}
