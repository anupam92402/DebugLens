import 'package:flutter/material.dart';

import '../../../../shared/theme/debug_theme.dart';

/// Compact 16-px copy icon, used inline in expansion content.
class CopyIcon extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;

  const CopyIcon({super.key, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(),
      color: DebugPalette.textMuted,
      icon: const Icon(Icons.copy, size: 16),
      onPressed: onTap,
    );
  }
}
