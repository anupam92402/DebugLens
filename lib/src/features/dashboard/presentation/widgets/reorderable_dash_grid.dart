import 'package:flutter/material.dart';

import '../../domain/dash_item.dart';
import 'dash_card.dart';

/// The dashboard's two-column grid, with long-press drag to rearrange tiles.
///
/// Flutter ships `ReorderableListView` but no reorderable *grid*, and a list
/// would cost the two-column layout — so the drag is wired by hand:
/// [LongPressDraggable] lifts a tile and the [DragTarget] wrapping every tile
/// reports the drop. Each cell is keyed by its route, so Flutter keeps element
/// identity (and the tile's own state) as cells swap positions.
class ReorderableDashGrid extends StatelessWidget {
  final List<DashItem> items;

  /// Called with [items] in their new order once a tile is dropped. The caller
  /// owns what that means — these may be a filtered view of a longer list.
  final ValueChanged<List<DashItem>> onReorder;

  const ReorderableDashGrid({
    super.key,
    required this.items,
    required this.onReorder,
  });

  static const int _columns = 2;
  static const double _spacing = 12;
  static const double _aspectRatio = 1.5;

  void _move(int from, int to) {
    if (from == to) return;
    final next = [...items];
    next.insert(to, next.removeAt(from));
    onReorder(next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The drag feedback renders in an Overlay, outside the grid's
        // constraints, so it has to be given the cell's size explicitly.
        final width =
            (constraints.maxWidth - _spacing * (_columns + 1)) / _columns;
        final cell = Size(width, width / _aspectRatio);
        return GridView.count(
          crossAxisCount: _columns,
          padding: const EdgeInsets.all(_spacing),
          mainAxisSpacing: _spacing,
          crossAxisSpacing: _spacing,
          childAspectRatio: _aspectRatio,
          children: [
            for (var i = 0; i < items.length; i++) _cell(i, cell),
          ],
        );
      },
    );
  }

  Widget _cell(int index, Size cell) {
    final item = items[index];
    final card = DashCard(item: item);
    return DragTarget<int>(
      key: ValueKey(item.route),
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => _move(details.data, index),
      builder: (context, candidate, _) => LongPressDraggable<int>(
        data: index,
        feedback: SizedBox.fromSize(
          size: cell,
          // The card's InkWell needs a Material ancestor, which the Overlay
          // doesn't provide.
          child: Material(
            type: MaterialType.transparency,
            child: Opacity(opacity: 0.9, child: card),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: card),
        // Nudge the tile the drag is hovering over, so the drop target reads.
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: candidate.isEmpty ? 1 : 1.06,
          child: card,
        ),
      ),
    );
  }
}
