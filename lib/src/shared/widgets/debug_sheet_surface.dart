import 'package:flutter/material.dart';

import 'glass_background.dart';

/// Rounded-top container for the panel's bottom sheets: an opaque panel fill
/// with a light gradient and a hairline border.
class DebugSheetSurface extends StatelessWidget {
  final Widget child;

  const DebugSheetSurface({super.key, required this.child});

  static const double _radius = 16;
  static const BorderRadius _corners = BorderRadius.vertical(
    top: Radius.circular(_radius),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _corners,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _corners,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                Colors.white.withValues(alpha: 0.14),
                GlassColors.bgMid,
              ),
              Color.alphaBlend(
                Colors.white.withValues(alpha: 0.05),
                GlassColors.bgMid,
              ),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: child,
      ),
    );
  }
}
