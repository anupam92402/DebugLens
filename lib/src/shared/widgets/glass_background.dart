import 'package:flutter/material.dart';

class GlassColors {
  GlassColors._();

  static const bgTop = Color(0xFF0B1020);
  static const bgMid = Color(0xFF111833);
  static const bgBottom = Color(0xFF0E1428);
}

/// Vibrant gradient + soft color blobs that sit behind the frosted glass so
/// the blur has something colorful to refract.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GlassColors.bgTop,
                  GlassColors.bgMid,
                  GlassColors.bgBottom,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
