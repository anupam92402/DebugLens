import 'package:flutter/material.dart';

import '../../domain/log_record.dart';
import '../../../../shared/util/set_toggle.dart';
import '../../../../shared/debug_strings.dart';

/// Level filter chips for the Logs screen: `All` plus one per [DebugLogLevel].
/// An empty [selectedLevels] means "All".
class LogFilterRow extends StatelessWidget {
  final Set<DebugLogLevel> selectedLevels;
  final ValueChanged<Set<DebugLogLevel>> onLevelsChanged;

  const LogFilterRow({
    super.key,
    required this.selectedLevels,
    required this.onLevelsChanged,
  });

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
                onSelected: (_) =>
                    onLevelsChanged(selectedLevels.toggled(level)),
              ),
            ),
        ],
      ),
    );
  }
}
