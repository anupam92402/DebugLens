import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/json_view.dart';
import 'copy_icon.dart';

/// "ARGUMENTS" header + copy button + JSON-pretty body. Extracted because
/// the same shape is reused for any future tile that wants a labeled
/// JSON block with copy.
class ArgumentsBlock extends StatelessWidget {
  final Object? arguments;
  final String Function(Object?) asText;
  final void Function(BuildContext, String, String) onCopy;

  const ArgumentsBlock({
    super.key,
    required this.arguments,
    required this.asText,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              DebugStrings.navigationArgumentsHeader,
              style: monoStyle(
                size: 11,
                weight: FontWeight.w700,
                color: DebugPalette.textMuted,
              ),
            ),
            const Spacer(),
            CopyIcon(
              tooltip: DebugStrings.navigationCopyArguments,
              onTap: () => onCopy(
                context,
                asText(arguments),
                DebugStrings.navigationArgumentsCopied,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        JsonView(arguments),
      ],
    );
  }
}
