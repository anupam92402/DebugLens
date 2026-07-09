import 'package:flutter/material.dart';

import '../debug_widgets.dart';

/// Fixed header row above the locale list. The flex / sized-box widths
/// mirror [LocaleRow] so the labels align vertically over their columns.
///
/// Extracted into its own widget because the layout commentary about
/// matching the copy-icon block widths is purely structural — it has no
/// business in the screen file once the row layout is shared.
class LocaleColumnHeader extends StatelessWidget {
  const LocaleColumnHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'KEY',
              style: monoStyle(
                size: 11,
                weight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          // Matches the copy-key icon block (4+13+8 = 25) in LocaleRow.
          const SizedBox(width: 25),
          Expanded(
            flex: 3,
            child: Text(
              'VALUE',
              style: monoStyle(
                size: 11,
                weight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          // Matches the trailing copy-value icon block (4+13 = 17).
          const SizedBox(width: 17),
        ],
      ),
    );
  }
}
