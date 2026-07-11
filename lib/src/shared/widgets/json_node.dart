import 'package:flutter/material.dart';

import 'json_engine.dart';
import 'text_styles.dart';
import '../theme/debug_colors.dart';

/// A single node in the JSON object tree — an expandable header for maps/lists,
/// an inline row for primitives. Recurses to render its children.
class JsonNode extends StatefulWidget {
  final Object? value;
  final String label;
  final String path;
  final bool root;
  final JsonSearch? search;
  final List<JsonTreeMatch>? matches;

  const JsonNode({
    super.key,
    required this.value,
    required this.label,
    required this.path,
    this.root = false,
    this.search,
    this.matches,
  });

  @override
  State<JsonNode> createState() => _JsonNodeState();
}

class _JsonNodeState extends State<JsonNode> {
  late bool _expanded = widget.root; // collapse non-root nodes by default

  /// Global index of this node's key/value match, or -1 if none.
  int _matchIndex({required bool isKey}) {
    final matches = widget.matches;
    if (matches == null) return -1;
    return matches.indexWhere((m) => m.path == widget.path && m.isKey == isKey);
  }

  bool get _descendantHasMatch =>
      widget.matches != null &&
      widget.matches!.any((m) => m.path.startsWith('${widget.path}/'));

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    if (v is Map) return _composite(_mapEntries(v), '{', '}');
    if (v is List) return _composite(_listEntries(v), '[', ']');
    return _leaf(v);
  }

  Iterable<MapEntry<String, Object?>> _mapEntries(Map<dynamic, dynamic> map) =>
      map.entries.map((e) => MapEntry(e.key.toString(), e.value));

  Iterable<MapEntry<String, Object?>> _listEntries(List<dynamic> list) =>
      list.asMap().entries.map((e) => MapEntry('[${e.key}]', e.value));

  Widget _composite(
    Iterable<MapEntry<String, Object?>> entries,
    String openBrace,
    String closeBrace,
  ) {
    final list = entries.toList();
    final summary = '$openBrace${list.length}$closeBrace';
    final search = widget.search;
    final accent = Theme.of(context).colorScheme.primary;

    // Force open while searching if a descendant matches, so the hit is seen.
    final expanded = _expanded || (search != null && _descendantHasMatch);

    final keyIndex = _matchIndex(isKey: true);
    final keyActive = search != null && keyIndex == search.activeIndex;

    final labelStyle = monoStyle(size: 12, color: DebugColors.textMuted);
    final header = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            expanded ? Icons.expand_more : Icons.chevron_right,
            size: 16,
            color: DebugColors.textMuted,
          ),
          if (widget.label.isNotEmpty)
            (keyIndex >= 0)
                ? Text.rich(
                    highlightSpan(
                      '${widget.label}: ',
                      search!.query,
                      labelStyle,
                      active: keyActive,
                      accent: accent,
                    ),
                  )
                : Text('${widget.label}: ', style: labelStyle),
          Text(
            summary,
            style: monoStyle(
              size: 12,
              color: DebugColors.info,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(4),
          child: keyActive
              ? KeyedSubtree(key: search!.activeKey, child: header)
              : header,
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in list)
                  JsonNode(
                    value: e.value,
                    label: e.key,
                    path: '${widget.path}/${e.key}',
                    search: widget.search,
                    matches: widget.matches,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _leaf(Object? v) {
    final (label, color) = _leafStyle(v);
    final search = widget.search;
    final accent = Theme.of(context).colorScheme.primary;

    final keyIndex = _matchIndex(isKey: true);
    final valueIndex = _matchIndex(isKey: false);
    final keyActive = search != null && keyIndex == search.activeIndex;
    final valueActive = search != null && valueIndex == search.activeIndex;

    final labelStyle = monoStyle(size: 12, color: DebugColors.textMuted);
    final valueStyle = monoStyle(size: 12, color: color);

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reserve the same indent as the composite chevron so siblings line
          // up vertically whether they're leaves or branches.
          const SizedBox(width: 16),
          if (widget.label.isNotEmpty)
            (keyIndex >= 0)
                ? Text.rich(
                    highlightSpan(
                      '${widget.label}: ',
                      search!.query,
                      labelStyle,
                      active: keyActive,
                      accent: accent,
                    ),
                  )
                : Text('${widget.label}: ', style: labelStyle),
          Expanded(
            child: (valueIndex >= 0)
                ? SelectableText.rich(
                    highlightSpan(
                      label,
                      search!.query,
                      valueStyle,
                      active: valueActive,
                      accent: accent,
                    ),
                  )
                : SelectableText(label, style: valueStyle),
          ),
        ],
      ),
    );

    final isActive = keyActive || valueActive;
    return isActive ? KeyedSubtree(key: search!.activeKey, child: row) : row;
  }

  /// Colors mirror common JSON syntax-highlighting conventions so types are
  /// easy to scan at a glance.
  (String, Color) _leafStyle(Object? v) {
    if (v == null) {
      return ('null', DebugColors.textMuted);
    }
    if (v is String) {
      return ('"$v"', DebugColors.success);
    }
    if (v is num) {
      return (v.toString(), DebugColors.warning);
    }
    if (v is bool) {
      return (v.toString(), DebugColors.info);
    }
    return (v.toString(), DebugColors.textPrimary);
  }
}
