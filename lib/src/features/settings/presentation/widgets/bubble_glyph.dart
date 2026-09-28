import 'package:flutter/material.dart';

import '../../../../shared/debug_constants.dart';
import '../../domain/bubble_style.dart';

/// [icon]'s mark at [size], tinted [color] unless the mark has its own.
class BubbleGlyph extends StatelessWidget {
  final BubbleIcon icon;
  final double size;
  final Color color;

  const BubbleGlyph({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => switch (icon) {
    BubbleIcon.flutter => FlutterLogo(size: size),
    // `package:` — the path must resolve against this package's assets.
    BubbleIcon.dashArt => Image.asset(
      DebugConstants.dashAssetPath,
      package: DebugConstants.packageName,
      width: size,
      height: size,
    ),
    // Safe: every remaining value declares an icon.
    _ => Icon(icon.icon!, size: size, color: icon.tint ?? color),
  };
}
