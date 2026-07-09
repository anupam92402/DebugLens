import 'package:flutter/material.dart';

import '../theme/debug_theme.dart';
import 'highlighted_raw_text.dart';
import 'json_engine.dart';
import 'text_styles.dart';

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
          : HighlightedRawText(text: pretty, search: search!),
    );
  }
}
