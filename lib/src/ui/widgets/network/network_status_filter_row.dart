import 'package:flutter/material.dart';

import '../../../core/models/network_entry.dart';

/// Horizontal chip row that filters the Network list by [NetworkStatusKind].
/// `null` selection = "All". Stateless — the screen owns the selected value
/// and the change callback.
class NetworkStatusFilterRow extends StatelessWidget {
  final NetworkStatusKind? selected;
  final ValueChanged<NetworkStatusKind?> onSelected;

  const NetworkStatusFilterRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  // Defined as a static const so the chip ordering is visible at a glance
  // and easy to extend with new filter kinds in one place.
  static const List<(String, NetworkStatusKind?)> _options = [
    ('All', null),
    ('Success', NetworkStatusKind.success),
    ('Error', NetworkStatusKind.error),
    ('Pending', NetworkStatusKind.pending),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final (label, kind) in _options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selected == kind,
                onSelected: (_) => onSelected(kind),
              ),
            ),
        ],
      ),
    );
  }
}
