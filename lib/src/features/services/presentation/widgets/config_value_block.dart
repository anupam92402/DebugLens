import 'package:flutter/material.dart';

import '../../../../shared/widgets/debug_widgets.dart';

/// One config value rendered verbatim in a code block, bounded and scrollable.
///
/// The bound is the point: a config value is regularly thousands of characters
/// — a JSON array, a URL list — and left unbounded it pushes a dialog's buttons
/// off the screen (and overflows it outright once the keyboard is up).
class ConfigValueBlock extends StatelessWidget {
  final String text;

  /// Passed through to [CodeBlock] — muted by default there, so pass a stronger
  /// colour for the value that is actually in force.
  final Color? color;

  /// How tall the block may get before it scrolls instead.
  ///
  /// Defaults to [defaultMaxHeight] — enough to read a long value in place. Pass
  /// something shorter where the dialog has more to fit, e.g. beside an editable
  /// field with the keyboard up.
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
