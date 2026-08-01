import 'package:flutter/material.dart';

import '../../../../shared/widgets/debug_widgets.dart';

/// One config value rendered verbatim in a code block, bounded and scrollable.
class ConfigValueBlock extends StatelessWidget {
  final String text;

  /// Passed through to [CodeBlock]; muted there by default.
  final Color? color;

  /// How tall the block may get before it scrolls instead.
  final double maxHeight;

  static const double defaultMaxHeight = 200;

  const ConfigValueBlock(
    this.text, {
    super.key,
    this.color,
    this.maxHeight = defaultMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(child: CodeBlock(text, color: color)),
    );
  }
}
