import 'package:flutter/material.dart';

import '../../domain/nav_event.dart';
import '../../../../shared/debug_strings.dart';

/// Chip row for filtering the Navigation Events tab by [NavRouteKind].
/// `_kinds.isEmpty` means "All" — the screen tracks the selected set.
///
/// `NavRouteKind.other` is intentionally excluded from the chip strip: it's
/// the observer's fallback for unclassified routes (rare, noisy as a
/// filter). Tiles still render the `other` kind label so unusual events
/// remain visible while scrolling.
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

  /// Pure helper — returns a new set with [kind] toggled. Lets [onChanged]
  /// receive an immutable snapshot rather than relying on the parent
  /// observing in-place mutation.
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
