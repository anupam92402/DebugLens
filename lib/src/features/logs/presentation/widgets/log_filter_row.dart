import 'package:flutter/material.dart';

import '../../domain/log_record.dart';
import '../../../../shared/debug_strings.dart';
import 'console_chip.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Horizontal chip strip for the Logs screen.
///
/// Two independent groups separated by a vertical divider:
///   1. Level filters (`All` + one chip per [DebugLogLevel]) — apply ONLY to
///      records with `source == custom`. Empty selected set = "All".
///   2. Console toggle — orthogonal source filter. Console rows are HIDDEN
///      by default; toggling the chip surfaces them in the feed.
class LogFilterRow extends StatelessWidget {
  final Set<DebugLogLevel> selectedLevels;
  final bool showConsole;
  final ValueChanged<Set<DebugLogLevel>> onLevelsChanged;
  final ValueChanged<bool> onShowConsoleChanged;

  const LogFilterRow({
    super.key,
    required this.selectedLevels,
    required this.showConsole,
    required this.onLevelsChanged,
    required this.onShowConsoleChanged,
  });

  Set<DebugLogLevel> _toggled(DebugLogLevel level) {
    final next = Set<DebugLogLevel>.from(selectedLevels);
    if (next.contains(level)) {
      next.remove(level);
    } else {
      next.add(level);
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text(DebugStrings.commonFilterAll),
              selected: selectedLevels.isEmpty,
              onSelected: (_) => onLevelsChanged(const {}),
            ),
          ),
          for (final level in DebugLogLevel.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(level.name),
                selected: selectedLevels.contains(level),
                onSelected: (_) => onLevelsChanged(_toggled(level)),
              ),
            ),
          // Visual separator between level filters (custom logs) and the
          // source filter (console).
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: VerticalDivider(width: 1, color: DebugColors.border),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ConsoleChip(
              selected: showConsole,
              onSelected: onShowConsoleChanged,
            ),
          ),
        ],
      ),
    );
  }
}
