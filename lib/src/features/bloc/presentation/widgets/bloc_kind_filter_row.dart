import 'package:flutter/material.dart';

import '../../domain/bloc_event.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/util/set_toggle.dart';

/// Chip row filtering the Bloc feed by [BlocActionKind]; empty = "All".
class BlocKindFilterRow extends StatelessWidget {
  final Set<BlocActionKind> selected;
  final ValueChanged<Set<BlocActionKind>> onChanged;

  const BlocKindFilterRow({
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
              onSelected: (_) => onChanged(const {}),
            ),
          ),
          for (final kind in BlocActionKind.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(kind.name),
                selected: selected.contains(kind),
                onSelected: (_) => onChanged(selected.toggled(kind)),
              ),
            ),
        ],
      ),
    );
  }
}
