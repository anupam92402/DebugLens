import 'package:flutter/material.dart';

import 'json_engine.dart';
import 'text_styles.dart';
import '../theme/debug_colors.dart';

/// Raw pretty-printed JSON rendered line-by-line so the line holding the active
/// match can be wrapped with the search's `activeKey` for scroll-to.
class HighlightedRawText extends StatelessWidget {
  final String text;
  final JsonSearch search;

  const HighlightedRawText({
    super.key,
    required this.text,
    required this.search,
  });

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
                : DebugColors.warning.withValues(alpha: 0.30),
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
