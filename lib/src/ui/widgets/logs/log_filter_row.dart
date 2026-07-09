import 'package:flutter/material.dart';

import '../../../core/debug_lens_logger.dart';
import '../../theme/debug_theme.dart';

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
              label: const Text('All'),
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
            child:
                VerticalDivider(width: 1, color: DebugPalette.border),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _ConsoleChip(
              selected: showConsole,
              onSelected: onShowConsoleChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// The console source-toggle chip. Lives in its own widget because its
/// custom colors / weight / avatar would clutter the filter row inline.
class _ConsoleChip extends StatelessWidget {
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _ConsoleChip({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: const Icon(
        Icons.terminal,
        size: 16,
        color: DebugPalette.console,
      ),
      label: const Text('console'),
      selected: selected,
      selectedColor: DebugPalette.console.withValues(alpha: 0.25),
      checkmarkColor: DebugPalette.console,
      side: BorderSide(
        color:
            DebugPalette.console.withValues(alpha: selected ? 0.7 : 0.35),
      ),
      labelStyle: TextStyle(
        color: selected ? DebugPalette.console : DebugPalette.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      onSelected: (_) => onSelected(!selected),
    );
  }
}
