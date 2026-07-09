import 'package:flutter/material.dart';

import '../../../core/models/bloc_event.dart';

/// Horizontal chip row for filtering the Bloc events feed by
/// [BlocActionKind]. Same pattern as `NavKindFilterRow` — `_kinds.isEmpty`
/// means "All".
class BlocKindFilterRow extends StatelessWidget {
  final Set<BlocActionKind> selected;
  final ValueChanged<Set<BlocActionKind>> onChanged;

  const BlocKindFilterRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Returns a new set with [kind] toggled. Immutable update keeps the
  /// parent screen's `setState` predictable.
  Set<BlocActionKind> _toggled(BlocActionKind kind) {
    final next = Set<BlocActionKind>.from(selected);
    if (next.contains(kind)) {
      next.remove(kind);
    } else {
      next.add(kind);
    }
    return next;
  }

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
              label: const Text('All'),
              selected: selected.isEmpty,
              onSelected: (_) => onChanged(const {}),
            ),
          ),
          for (final kind in BlocActionKind.values)
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
}
