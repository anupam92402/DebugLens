import 'package:flutter/material.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';

/// The console source-toggle chip. Lives in its own widget because its
/// custom colors / weight / avatar would clutter the filter row inline.
class ConsoleChip extends StatelessWidget {
  final bool selected;
  final ValueChanged<bool> onSelected;

  const ConsoleChip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: const Icon(Icons.terminal, size: 16, color: DebugPalette.console),
      label: const Text(DebugStrings.logsConsole),
      selected: selected,
      selectedColor: DebugPalette.console.withValues(alpha: 0.25),
      checkmarkColor: DebugPalette.console,
      side: BorderSide(
        color: DebugPalette.console.withValues(alpha: selected ? 0.7 : 0.35),
      ),
      labelStyle: TextStyle(
        color: selected ? DebugPalette.console : DebugPalette.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      onSelected: (_) => onSelected(!selected),
    );
  }
}
