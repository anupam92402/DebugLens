import 'dart:convert';

import 'package:flutter/material.dart';

import '../debug_strings.dart';
import '../theme/debug_theme.dart';
import 'debug_widgets.dart';

/// Pretty-prints any JSON-encodable value to an indented string. Falls back to
/// `toString()` for anything that can't be encoded.
String prettyJson(Object? data) {
  if (data == null) return 'null';
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data.toString();
  }
}

/// Search context threaded into the JSON viewers so matches can be highlighted
/// and the currently focused match scrolled into view.
///
/// [query] is already lower-cased and non-empty. [activeIndex] selects which
/// match (in display order) gets the strong highlight; the widget rendering it
/// attaches [activeKey] so the host can `Scrollable.ensureVisible` it.
@immutable
class JsonSearch {
  final String query;
  final int activeIndex;
  final GlobalKey activeKey;

  const JsonSearch({
    required this.query,
    required this.activeIndex,
    required this.activeKey,
  });
}

/// Returns the number of matches for [query] in [data] under [mode]. Tree mode
/// counts matching key/value *segments*; raw mode counts text occurrences. The
/// two can differ — each mode navigates within its own representation.
int jsonMatchCount(Object? data, String query, JsonViewMode mode) {
  final q = query.toLowerCase();
  if (q.isEmpty) return 0;
  return mode == JsonViewMode.tree
      ? _collectTreeMatches(data, q).length
      : _countOccurrences(prettyJson(data).toLowerCase(), q);
}

int _countOccurrences(String lowerText, String q) {
  var count = 0;
  var i = 0;
  while (true) {
    final f = lowerText.indexOf(q, i);
    if (f < 0) break;
    count++;
    i = f + q.length;
  }
  return count;
}

/// One matching segment in the object tree, identified by its path (unique per
/// node) and whether the match is on the key or the leaf value.
@immutable
class _TreeMatch {
  final String path;
  final bool isKey;

  const _TreeMatch(this.path, this.isKey);
}

/// The text a leaf renders for [v] — strings are quoted to mirror the tree.
String _leafLabel(Object? v) {
  if (v == null) return 'null';
  if (v is String) return '"$v"';
  return v.toString();
}

/// Walks [data] depth-first (display order) collecting every key/value segment
/// containing [q] (already lower-cased). Used both to count matches and to map
/// an `activeIndex` back to a specific node during rendering.
List<_TreeMatch> _collectTreeMatches(Object? data, String q) {
  final out = <_TreeMatch>[];
  void walk(Object? v, String path, String label) {
    if (label.isNotEmpty && label.toLowerCase().contains(q)) {
      out.add(_TreeMatch(path, true));
    }
    if (v is Map) {
      for (final e in v.entries) {
        walk(e.value, '$path/${e.key}', e.key.toString());
      }
    } else if (v is List) {
      for (var i = 0; i < v.length; i++) {
        walk(v[i], '$path/[$i]', '[$i]');
      }
    } else if (_leafLabel(v).toLowerCase().contains(q)) {
      out.add(_TreeMatch(path, false));
    }
  }

  walk(data, '', '');
  return out;
}

/// Builds a span highlighting every occurrence of [q] (lower-cased) in [text].
/// [active] selects the strong (focused-match) highlight.
TextSpan _highlightAll(
  String text,
  String q,
  TextStyle base, {
  required bool active,
  required Color accent,
}) {
  if (q.isEmpty) return TextSpan(text: text, style: base);
  final lower = text.toLowerCase();
  final hl = base.copyWith(
    backgroundColor: active
        ? accent
        : DebugPalette.warning.withValues(alpha: 0.30),
    color: active ? Colors.black : base.color,
    fontWeight: FontWeight.w700,
  );
  final spans = <TextSpan>[];
  var i = 0;
  while (true) {
    final f = lower.indexOf(q, i);
    if (f < 0) {
      if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
      break;
    }
    if (f > i) spans.add(TextSpan(text: text.substring(i, f)));
    spans.add(TextSpan(text: text.substring(f, f + q.length), style: hl));
    i = f + q.length;
  }
  return TextSpan(style: base, children: spans);
}

/// Pretty-prints any JSON-encodable value into a selectable monospace block.
/// When [search] is set, matches are highlighted in place.
class JsonView extends StatelessWidget {
  final Object? data;
  final JsonSearch? search;

  const JsonView(this.data, {super.key, this.search});

  @override
  Widget build(BuildContext context) {
    final pretty = prettyJson(data);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DebugPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DebugPalette.border),
      ),
      child: search == null
          ? SelectableText(pretty, style: monoStyle(size: 12))
          : _HighlightedRawText(text: pretty, search: search!),
    );
  }
}

/// Raw pretty-printed JSON rendered line-by-line so the line holding the active
/// match can be wrapped with the search's `activeKey` for scroll-to.
class _HighlightedRawText extends StatelessWidget {
  final String text;
  final JsonSearch search;

  const _HighlightedRawText({required this.text, required this.search});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final base = monoStyle(size: 12);
    final q = search.query;
    final lines = text.split('\n');
    final rows = <Widget>[];
    var global = 0;
    for (final line in lines) {
      final (span, hasActive, next) = _rawLineSpan(
        line,
        q,
        base,
        global,
        search.activeIndex,
        accent,
      );
      global = next;
      final row = SelectableText.rich(span);
      rows.add(
        hasActive ? KeyedSubtree(key: search.activeKey, child: row) : row,
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  /// Builds one line's span, numbering each occurrence from [startGlobal] so
  /// the active occurrence (== [activeIndex]) can be emphasised. Returns the
  /// span, whether this line owns the active match, and the next global index.
  (TextSpan, bool, int) _rawLineSpan(
    String line,
    String q,
    TextStyle base,
    int startGlobal,
    int activeIndex,
    Color accent,
  ) {
    final lower = line.toLowerCase();
    final spans = <TextSpan>[];
    var i = 0;
    var g = startGlobal;
    var hasActive = false;
    while (true) {
      final f = lower.indexOf(q, i);
      if (f < 0) {
        if (i < line.length) spans.add(TextSpan(text: line.substring(i)));
        break;
      }
      if (f > i) spans.add(TextSpan(text: line.substring(i, f)));
      final active = g == activeIndex;
      if (active) hasActive = true;
      spans.add(
        TextSpan(
          text: line.substring(f, f + q.length),
          style: base.copyWith(
            backgroundColor: active
                ? accent
                : DebugPalette.warning.withValues(alpha: 0.30),
            color: active ? Colors.black : base.color,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      g++;
      i = f + q.length;
    }
    return (TextSpan(style: base, children: spans), hasActive, g);
  }
}

/// Selection between the tree and raw JSON viewer.
enum JsonViewMode { tree, raw }

/// Composite that lets the user toggle between an expandable object tree
/// (`tree`) and pretty-printed JSON text (`raw`) — mirrors the dual-mode
/// viewer in we_logger's chucker, but built on our own widgets.
///
/// The view mode can be left uncontrolled (manages its own state from
/// [initialMode]) or controlled by passing [mode] + [onModeChanged]. When a
/// [search] is supplied, matches are highlighted in whichever mode is active.
class JsonViewer extends StatefulWidget {
  final Object? data;
  final JsonViewMode initialMode;

  /// Controlled view mode. When non-null, the widget renders this mode and
  /// reports toggles through [onModeChanged] instead of tracking its own.
  final JsonViewMode? mode;
  final ValueChanged<JsonViewMode>? onModeChanged;

  /// Active search; when non-null, matches are highlighted in the active mode.
  final JsonSearch? search;

  /// When provided, a `COPY` text button is drawn at the top-right of the
  /// Object/JSON toggle row. It copies the pretty-printed body regardless of
  /// which view mode is active, so the affordance matches the SectionCards on
  /// the Overview tab. [copyLabel] is used in the resulting toast.
  final void Function(String text, String label)? onCopy;
  final String copyLabel;

  const JsonViewer(
    this.data, {
    super.key,
    this.initialMode = JsonViewMode.tree,
    this.mode,
    this.onModeChanged,
    this.search,
    this.onCopy,
    this.copyLabel = DebugStrings.commonBodyLabel,
  });

  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  late JsonViewMode _internalMode = widget.initialMode;

  JsonViewMode get _mode => widget.mode ?? _internalMode;

  void _select(JsonViewMode mode) {
    if (widget.onModeChanged != null) {
      widget.onModeChanged!(mode);
    } else {
      setState(() => _internalMode = mode);
    }
  }

  /// Pretty-printed copy text — same representation as the raw JSON view, so
  /// the COPY button yields identical output in both Object and JSON modes.
  String get _copyText => prettyJson(widget.data);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChoiceChip(
              label: const Text(DebugStrings.jsonObjectMode),
              selected: _mode == JsonViewMode.tree,
              onSelected: (_) => _select(JsonViewMode.tree),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text(DebugStrings.jsonRawMode),
              selected: _mode == JsonViewMode.raw,
              onSelected: (_) => _select(JsonViewMode.raw),
            ),
            if (widget.onCopy != null) ...[
              const Spacer(),
              InkWell(
                onTap: () => widget.onCopy!(_copyText, widget.copyLabel),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    DebugStrings.commonCopyButton,
                    style: monoStyle(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        switch (_mode) {
          JsonViewMode.tree => JsonObjectTree(
            widget.data,
            search: widget.search,
          ),
          JsonViewMode.raw => JsonView(widget.data, search: widget.search),
        },
      ],
    );
  }
}

/// Recursive tree view for any JSON-encodable value. Maps and lists are
/// rendered as expandable headers; primitives as inline rows. Each composite
/// node manages its own expand/collapse state — the root expands by default.
///
/// Simpler-than-chucker design: a single recursive widget instead of four
/// inter-dependent files. Good enough for inspecting request/response bodies
/// without dragging in a tree-rendering dependency.
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
        : _collectTreeMatches(data, search!.query);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DebugPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DebugPalette.border),
      ),
      child: _JsonNode(
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

class _JsonNode extends StatefulWidget {
  final Object? value;
  final String label;
  final String path;
  final bool root;
  final JsonSearch? search;
  final List<_TreeMatch>? matches;

  const _JsonNode({
    required this.value,
    required this.label,
    required this.path,
    this.root = false,
    this.search,
    this.matches,
  });

  @override
  State<_JsonNode> createState() => _JsonNodeState();
}

class _JsonNodeState extends State<_JsonNode> {
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

    final labelStyle = monoStyle(size: 12, color: DebugPalette.textMuted);
    final header = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            expanded ? Icons.expand_more : Icons.chevron_right,
            size: 16,
            color: DebugPalette.textMuted,
          ),
          if (widget.label.isNotEmpty)
            (keyIndex >= 0)
                ? Text.rich(
                    _highlightAll(
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
              color: DebugPalette.info,
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
                  _JsonNode(
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

    final labelStyle = monoStyle(size: 12, color: DebugPalette.textMuted);
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
                    _highlightAll(
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
                    _highlightAll(
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
      return ('null', DebugPalette.textMuted);
    }
    if (v is String) {
      return ('"$v"', DebugPalette.success);
    }
    if (v is num) {
      return (v.toString(), DebugPalette.warning);
    }
    if (v is bool) {
      return (v.toString(), DebugPalette.info);
    }
    return (v.toString(), DebugPalette.textPrimary);
  }
}
