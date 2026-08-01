import 'package:flutter/material.dart';

import '../../../shared/debug_constants.dart';
import '../../../shared/theme/debug_colors.dart';

/// Icon shown on the bubble that opens the panel.
enum BubbleIcon {
  dash('Dash', Icons.flutter_dash_sharp),
  dashArt('Dash 3D', null),
  flutter('Flutter', null),
  android('Android', Icons.android, DebugColors.androidGreen),
  apple('Apple', Icons.apple),
  spark('Spark', Icons.auto_awesome, DebugColors.geminiPurple);

  const BubbleIcon(this.label, this.icon, [this.tint]);

  final String label;

  /// Null for the two marks that aren't font glyphs — [dashArt] and [flutter].
  /// Use [glyph] rather than reading this directly.
  final IconData? icon;

  /// Fixed colour for a brand mark; [glyph] uses it instead of the caller's.
  final Color? tint;

  /// The mark to render at [size].
  Widget glyph({required double size, required Color color}) => switch (this) {
    BubbleIcon.flutter => FlutterLogo(size: size),
    // `package:` — the path must resolve against this package's assets.
    BubbleIcon.dashArt => Image.asset(
      DebugConstants.dashAssetPath,
      package: DebugConstants.packageName,
      width: size,
      height: size,
    ),
    // Safe: every remaining value declares an icon.
    _ => Icon(icon!, size: size, color: tint ?? color),
  };

  /// The shipped default, and the fallback for an unrecognised saved value.
  static const BubbleIcon fallback = dashArt;

  static BubbleIcon byName(String? name) =>
      values.firstWhere((i) => i.name == name, orElse: () => fallback);
}

/// Where the bubble rests.
enum BubbleCorner {
  topLeft('Top left', Alignment.topLeft),
  topRight('Top right', Alignment.topRight),
  centerLeft('Middle left', Alignment.centerLeft),
  centerRight('Middle right', Alignment.centerRight),
  bottomLeft('Bottom left', Alignment.bottomLeft),
  bottomRight('Bottom right', Alignment.bottomRight);

  const BubbleCorner(this.label, this.alignment);

  final String label;

  /// Used to place the selector's dot, and to resolve the on-screen offset.
  final Alignment alignment;

  static const BubbleCorner fallback = bottomLeft;

  static BubbleCorner byName(String? name) =>
      values.firstWhere((c) => c.name == name, orElse: () => fallback);

  /// Top-left offset for a [size]-square bubble inside [screen], inset by
  /// [safeArea] so an anchor never lands under a status or navigation bar.
  Offset offsetIn(Size screen, EdgeInsets safeArea, double size) {
    const margin = 16.0;
    final left = margin + safeArea.left;
    final right = screen.width - size - margin - safeArea.right;
    final top = margin + safeArea.top;
    final bottom = screen.height - size - margin - safeArea.bottom;
    final middle = (screen.height - size) / 2;

    return switch (this) {
      BubbleCorner.topLeft => Offset(left, top),
      BubbleCorner.topRight => Offset(right, top),
      BubbleCorner.centerLeft => Offset(left, middle),
      BubbleCorner.centerRight => Offset(right, middle),
      BubbleCorner.bottomLeft => Offset(left, bottom),
      BubbleCorner.bottomRight => Offset(right, bottom),
    };
  }
}
