import 'package:flutter/material.dart';

import '../theme/debug_colors.dart';
import 'text_styles.dart';

/// Monospace text in a code-style container — the panel's standard treatment
/// for anything meant to be read verbatim: a stack trace, an exception, a
/// snippet to copy into the host app.
///
/// Selectable, so a caller can take part of it without a copy button.
class CodeBlock extends StatelessWidget {
  final String text;

  /// Text colour. Defaults to muted, since a block is usually secondary to the
  /// header above it; pass [DebugColors.error] for a failure.
  final Color? color;

  /// Whether the text can be selected. Off for anything rendered by an error
  /// widget: `SelectableText` needs `MaterialLocalizations` for its context
  /// menu, and an error can surface where that doesn't exist.
  final bool selectable;

  const CodeBlock(this.text, {super.key, this.color, this.selectable = true});

  @override
  Widget build(BuildContext context) {
    final style = monoStyle(size: 12, color: color ?? DebugColors.textMuted);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DebugColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: selectable
          ? SelectableText(text, style: style)
          : Text(text, style: style),
    );
  }
}
