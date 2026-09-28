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
    final search = widget.search;
    final keyIndex = _matchIndex(isKey: true);
    if (v is Map || v is List) {
      return _JsonBranch(
        entries: v is Map ? _mapEntries(v) : _listEntries(v as List),
        openBrace: v is Map ? '{' : '[',
        closeBrace: v is Map ? '}' : ']',
        label: widget.label,
        path: widget.path,
        search: search,
        matches: widget.matches,
        keyIndex: keyIndex,
        // Forced open while searching if a descendant matches, so the hit is
        // seen.
        expanded: _expanded || (search != null && _descendantHasMatch),
        onToggle: () => setState(() => _expanded = !_expanded),
      );
    }
    return _JsonLeaf(
      value: v,
      label: widget.label,
      search: search,
      keyIndex: keyIndex,
      valueIndex: _matchIndex(isKey: false),
    );
  }

  List<MapEntry<String, Object?>> _mapEntries(Map<dynamic, dynamic> map) => [
    for (final e in map.entries) MapEntry(e.key.toString(), e.value),
  ];

  List<MapEntry<String, Object?>> _listEntries(List<dynamic> list) => [
    for (final e in list.asMap().entries) MapEntry('[${e.key}]', e.value),
  ];
}

/// A map or list: a tappable header with its size, and its children when
/// [expanded].
class _JsonBranch extends StatelessWidget {
  final List<MapEntry<String, Object?>> entries;
  final String openBrace;
  final String closeBrace;
  final String label;
  final String path;
  final JsonSearch? search;
  final List<JsonTreeMatch>? matches;

  /// Global index of this node's key match, or -1.
  final int keyIndex;
  final bool expanded;
  final VoidCallback onToggle;

  const _JsonBranch({
    required this.entries,
    required this.openBrace,
    required this.closeBrace,
    required this.label,
    required this.path,
    required this.search,
    required this.matches,
    required this.keyIndex,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final search = this.search;
    final summary = '$openBrace${entries.length}$closeBrace';
    final accent = Theme.of(context).colorScheme.primary;
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
          if (label.isNotEmpty)
            (keyIndex >= 0)
                ? Text.rich(
                    highlightSpan(
                      '$label: ',
                      search!.query,
                      labelStyle,
                      active: keyActive,
                      accent: accent,
                    ),
                  )
                : Text('$label: ', style: labelStyle),
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
          onTap: onToggle,
          borderRadius: BorderRadius.circular(4),
          child: keyActive
              ? KeyedSubtree(key: search.activeKey, child: header)
              : header,
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in entries)
                  JsonNode(
                    value: e.value,
                    label: e.key,
                    path: '$path/${e.key}',
                    search: search,
                    matches: matches,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A primitive: its key and its value, coloured by type.
class _JsonLeaf extends StatelessWidget {
  final Object? value;
  final String label;
  final JsonSearch? search;

  /// Global indexes of this node's key and value matches, or -1.
  final int keyIndex;
  final int valueIndex;

  const _JsonLeaf({
    required this.value,
    required this.label,
    required this.search,
    required this.keyIndex,
    required this.valueIndex,
  });

  @override
  Widget build(BuildContext context) {
    final search = this.search;
    final (text, color) = _style(value);
    final accent = Theme.of(context).colorScheme.primary;
    final keyActive = search != null && keyIndex == search.activeIndex;
    final valueActive = search != null && valueIndex == search.activeIndex;

    final labelStyle = monoStyle(size: 12, color: DebugColors.textMuted);
    final valueStyle = monoStyle(size: 12, color: color);

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reserve the same indent as the branch chevron so siblings line
          // up vertically whether they're leaves or branches.
          const SizedBox(width: 16),
          if (label.isNotEmpty)
            (keyIndex >= 0)
                ? Text.rich(
                    highlightSpan(
                      '$label: ',
                      search!.query,
                      labelStyle,
                      active: keyActive,
                      accent: accent,
                    ),
                  )
                : Text('$label: ', style: labelStyle),
          Expanded(
            child: (valueIndex >= 0)
                ? SelectableText.rich(
                    highlightSpan(
                      text,
                      search!.query,
                      valueStyle,
                      active: valueActive,
                      accent: accent,
                    ),
                  )
                : SelectableText(text, style: valueStyle),
          ),
        ],
      ),
    );

    final isActive = keyActive || valueActive;
    return isActive ? KeyedSubtree(key: search.activeKey, child: row) : row;
  }

  /// Colors mirror common JSON syntax-highlighting conventions so types are
  /// easy to scan at a glance.
  static (String, Color) _style(Object? v) {
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
