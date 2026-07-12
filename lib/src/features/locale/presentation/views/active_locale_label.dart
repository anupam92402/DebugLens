import 'package:flutter/material.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Compact AppBar action showing the currently-active locale label
/// (e.g. "English"), with a small language icon.
class ActiveLocaleLabel extends StatelessWidget {
  final String label;

  const ActiveLocaleLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          const Icon(Icons.language, size: 14, color: DebugColors.textMuted),
          const SizedBox(width: 6),
          Text(label, style: monoStyle(size: 12, color: DebugColors.textMuted)),
        ],
      ),
    );
  }
}
