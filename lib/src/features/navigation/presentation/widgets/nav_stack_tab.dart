import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'stack_row.dart';
import 'stack_section_header.dart';

/// Stack tab body: the live route stack per tracked navigator.
class NavStackTab extends StatelessWidget {
  final bool hideDebugLens;

  const NavStackTab({super.key, this.hideDebugLens = false});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final raw = context.watch<DebugStore>().navStacks;

    final stacks = <String, List<String>>{};
    for (final entry in raw.entries) {
      final rows = hideDebugLens
          ? entry.value.where((n) => !n.startsWith(DebugRoutes.prefix)).toList()
          : entry.value;
      if (rows.isNotEmpty) stacks[entry.key] = rows;
    }

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

  /// Rows for one navigator's stack, top first, level-numbered.
  List<Widget> _stackRows(Color accent, List<String> stack) {
    /// top first = current screen
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
