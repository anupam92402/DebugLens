import 'package:flutter/material.dart';

import '../../domain/nav_event.dart';
import '../../../../shared/debug_strings.dart';

/// Chip row to filter Events by route kind; empty selection means All.
class NavKindFilterRow extends StatelessWidget {
  final Set<NavRouteKind> selected;
  final ValueChanged<Set<NavRouteKind>> onChanged;

  const NavKindFilterRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 8),
            child: ChoiceChip(
              label: const Text(DebugStrings.commonFilterAll),
              selected: selected.isEmpty,
              onSelected: (_) => onChanged({}),
            ),
          ),

          /// 'other' (unclassified) is omitted from filters.
          for (final kind in NavRouteKind.values)
            if (kind != NavRouteKind.other)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(kind.name),
                  selected: selected.contains(kind),
                  onSelected: (_) => onChanged(_toggled(kind)),
                ),
              ),
        ],
      ),
    );
  }

  /// Returns a copy of the selection with [kind] toggled.
  Set<NavRouteKind> _toggled(NavRouteKind kind) {
    final next = Set<NavRouteKind>.from(selected);
    if (next.contains(kind)) {
      next.remove(kind);
    } else {
      next.add(kind);
    }
    return next;
  }
}
