import 'package:flutter/material.dart';

import '../debug_strings.dart';
import '../theme/debug_theme.dart';
import 'glass.dart';
import 'text_styles.dart';

/// Titled, bordered container used to group content on detail screens.
///
/// When [onCopy] is provided, a compact `Copy` text button is drawn at the
/// top-right of the title row — same affordance as we_logger's chucker
/// overview, where every block has a one-tap copy.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onCopy;

  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || onCopy != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!.toUpperCase(),
                        style: monoStyle(
                          size: 11,
                          weight: FontWeight.w700,
                          color: DebugPalette.textMuted,
                        ),
                      ),
                    ),
                  if (onCopy != null)
                    InkWell(
                      onTap: onCopy,
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
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
