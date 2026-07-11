import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/debug_colors.dart';

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

/// Selection between the tree and raw JSON viewer.
enum JsonViewMode { tree, raw }

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
      ? collectTreeMatches(data, q).length
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
class JsonTreeMatch {
  final String path;
  final bool isKey;

  const JsonTreeMatch(this.path, this.isKey);
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
List<JsonTreeMatch> collectTreeMatches(Object? data, String q) {
  final out = <JsonTreeMatch>[];
  void walk(Object? v, String path, String label) {
    if (label.isNotEmpty && label.toLowerCase().contains(q)) {
      out.add(JsonTreeMatch(path, true));
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
      out.add(JsonTreeMatch(path, false));
    }
  }

  walk(data, '', '');
  return out;
}

/// Builds a span highlighting every occurrence of [q] (lower-cased) in [text].
/// [active] selects the strong (focused-match) highlight.
TextSpan highlightSpan(
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
        : DebugColors.warning.withValues(alpha: 0.30),
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
