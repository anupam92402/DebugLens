import 'package:flutter/material.dart';

import '../../domain/network_entry.dart';
import '../../../../shared/debug_strings.dart';

/// Chip row filtering the Network list by [NetworkStatusKind]; null = "All".
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
    (DebugStrings.commonFilterAll, null),
    (DebugStrings.networkStatusSuccess, NetworkStatusKind.success),
    (DebugStrings.networkStatusError, NetworkStatusKind.error),
    (DebugStrings.networkStatusPending, NetworkStatusKind.pending),
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
