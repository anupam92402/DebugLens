import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// A frosted-glass surface: blurs whatever is behind it, with a translucent
/// gradient fill and a hairline highlight border.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tint;
  final double radius;
  final double blur;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.tint,
    this.radius = 16,
    this.blur = 16,
  });

  @override
  Widget build(BuildContext context) {
    Widget surface = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: tint == null
                  ? [
                      Colors.white.withValues(alpha: 0.14),
                      Colors.white.withValues(alpha: 0.05),
                    ]
                  : [
                      tint!.withValues(alpha: 0.22),
                      tint!.withValues(alpha: 0.06),
                    ],
            ),
            border: Border.all(
              color: (tint ?? Colors.white).withValues(
                alpha: tint == null ? 0.18 : 0.32,
              ),
            ),
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );
    if (margin != null) surface = Padding(padding: margin!, child: surface);
    return surface;
  }
}
