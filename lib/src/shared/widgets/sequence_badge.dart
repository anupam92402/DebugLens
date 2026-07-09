import 'package:flutter/material.dart';

import '../theme/debug_theme.dart';
import 'debug_widgets.dart';

/// Fixed-width pill showing a small index — used for the event sequence
/// number on the Events tab and the level number in the Stack tab. Shared
/// between both so they line up visually.
class SequenceBadge extends StatelessWidget {
  final String label;

  const SequenceBadge(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DebugPalette.border),
      ),
      child: Text(
        label,
        style: monoStyle(size: 12, color: DebugPalette.textMuted),
      ),
    );
  }
}
