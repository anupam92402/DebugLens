import 'package:flutter/material.dart';

import 'json_engine.dart';
import 'json_node.dart';
import '../theme/debug_colors.dart';

/// Recursive tree view for any JSON-encodable value. Maps and lists are
/// rendered as expandable headers; primitives as inline rows. Delegates each
/// node to [JsonNode], which manages its own expand/collapse state.
class JsonObjectTree extends StatelessWidget {
  final Object? data;
  final JsonSearch? search;

  const JsonObjectTree(this.data, {super.key, this.search});

  @override
  Widget build(BuildContext context) {
    // Pre-computed once and shared down the tree so each node can map its own
    // key/value segment to a global match index without re-walking the data.
    final matches = search == null
        ? null
        : collectTreeMatches(data, search!.query);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DebugColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DebugColors.border),
      ),
      child: JsonNode(
        value: data,
        label: '',
        path: '',
        root: true,
        search: search,
        matches: matches,
      ),
    );
  }
}
