import 'package:flutter/material.dart';

import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'locale_row.dart';

/// One collapsible category block on the Locale screen: a tappable header
/// (chevron + category name + entry count) that expands to reveal the
/// category's `key → value` rows.
///
/// Expansion is controlled by the parent ([expanded] + [onToggle]) so the
/// screen can keep one source of truth — e.g. auto-expanding every section
/// while a search is active, then restoring per-section state when it clears.
class LocaleCategorySection extends StatelessWidget {
  final String category;
  final List<MapEntry<String, String>> entries;
  final bool expanded;
  final VoidCallback onToggle;

  const LocaleCategorySection({
    super.key,
    required this.category,
    required this.entries,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    category,
                    style: monoStyle(
                      size: 13,
                      weight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                // Entry count, e.g. "6".
                Text(
                  '${entries.length}',
                  style: monoStyle(size: 12, color: DebugPalette.textMuted),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          for (final entry in entries) LocaleRow(entry: entry),
        const Divider(height: 1, color: DebugPalette.border),
      ],
    );
  }
}
