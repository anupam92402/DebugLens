import 'package:flutter/material.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Compact AppBar action showing the currently-active locale label
/// (e.g. "English"). Pulled out so the icon + spacing logic is colocated.
class ActiveLocaleLabel extends StatelessWidget {
  final String label;

  const ActiveLocaleLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          const Icon(Icons.language, size: 14, color: DebugPalette.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: monoStyle(size: 12, color: DebugPalette.textMuted),
          ),
        ],
      ),
    );
  }
}
