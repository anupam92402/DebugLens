import 'package:flutter/material.dart';

import '../theme/debug_colors.dart';

/// Compact copy icon used inline next to copyable text (KV rows, JSON blocks,
/// locale rows). [padding] positions it in tight row layouts; [size] defaults
/// to 16 (locale rows use 13).
class CopyIcon extends StatelessWidget {
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  final double size;
  final VoidCallback onTap;

  const CopyIcon({
    super.key,
    this.tooltip,
    this.padding = EdgeInsets.zero,
    this.size = 16,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(),
        color: DebugColors.textMuted,
        icon: Icon(Icons.copy, size: size),
        onPressed: onTap,
      ),
    );
  }
}
