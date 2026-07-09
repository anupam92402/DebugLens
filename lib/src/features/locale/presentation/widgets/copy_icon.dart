import 'package:flutter/material.dart';
import '../../../../shared/theme/debug_theme.dart';

/// Compact tap-target wrapping a 13-px copy icon. Padding is passed in so
/// the leading vs trailing icon (different left/right margins) share the
/// same widget without an extra prop.
class CopyIcon extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final VoidCallback onTap;

  const CopyIcon({super.key, required this.padding, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: const Icon(
          Icons.content_copy,
          size: 13,
          color: DebugPalette.textMuted,
        ),
      ),
    );
  }
}
