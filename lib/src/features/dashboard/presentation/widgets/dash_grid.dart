import 'package:flutter/material.dart';

import '../../domain/dash_item.dart';
import 'dash_card.dart';

/// The dashboard's two-column grid of inspector tiles.
///
/// Each cell is keyed by its route so Flutter keeps element identity (and the
/// tile's own state) as cells come and go with role filtering.
class DashGrid extends StatelessWidget {
  final List<DashItem> items;

  /// Optional [GlobalKey] per route, so a caller can measure one specific tile
  /// — the first-run tour points at the first one this way. Returning null for a
  /// route leaves that tile unkeyed.
  ///
  /// At most one tile per key: a `GlobalKey` may only be in the tree once.
  final GlobalKey? Function(String route)? cardKey;

  const DashGrid({super.key, required this.items, this.cardKey});

  static const int _columns = 2;
  static const double _spacing = 12;
  static const double _aspectRatio = 1.5;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: _columns,
      padding: const EdgeInsets.all(_spacing),
      mainAxisSpacing: _spacing,
      crossAxisSpacing: _spacing,
      childAspectRatio: _aspectRatio,
      children: [
        for (final item in items)
          DashCard(
            key: cardKey?.call(item.route) ?? ValueKey(item.route),
            item: item,
          ),
      ],
    );
  }
}
