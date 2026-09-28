import 'package:flutter/material.dart';

import '../debug_strings.dart';
import 'text_styles.dart';
import '../theme/debug_colors.dart';

/// Titled, bordered container used to group content on detail screens.
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

  static const BorderRadius _corners = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: ClipRRect(
        borderRadius: _corners,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: _corners,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
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
                              color: DebugColors.textMuted,
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
        ),
      ),
    );
  }
}
