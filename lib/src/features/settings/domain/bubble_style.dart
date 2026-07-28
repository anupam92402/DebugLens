import 'package:flutter/material.dart';

import '../../../shared/debug_constants.dart';

/// Icon shown on the bubble that opens the panel.
///
/// A short list on purpose — the point is to move the bubble out of the way of
/// whatever the host app puts in that corner, or to tell two builds apart, not
/// to offer a theme.
enum BubbleIcon {
  dash('Dash', Icons.flutter_dash_sharp),
  dashArt('Dash 3D', null),
  flutter('Flutter', null),
  bug('Bug', Icons.bug_report),
  eye('Eye', Icons.visibility_outlined),
  spark('Spark', Icons.auto_awesome);

  const BubbleIcon(this.label, this.icon);

  final String label;

  /// Null for the two marks that aren't font glyphs — [dashArt] and [flutter].
  /// Use [glyph] rather than reading this directly.
  final IconData? icon;

  /// The mark to render at [size].
  ///
  /// [color] is ignored by [dashArt] and [flutter]: both are multi-coloured by
  /// definition, which is why neither can just be another `IconData`.
  Widget glyph({required double size, required Color color}) => switch (this) {
    BubbleIcon.flutter => FlutterLogo(size: size),
    // `package:` is essential — without it the path resolves against the host
    // app's assets and fails for everyone but this package's own example.
    BubbleIcon.dashArt => Image.asset(
      DebugConstants.dashAssetPath,
      package: DebugConstants.packageName,
      width: size,
      height: size,
    ),
    // Safe: every remaining value declares an icon.
    _ => Icon(icon!, size: size, color: color),
  };

  /// The shipped default, and the fallback for an unreadable saved value.
  static const BubbleIcon fallback = dash;

  static BubbleIcon byName(String? name) =>
      values.firstWhere((i) => i.name == name, orElse: () => fallback);
}

/// Where the bubble rests.
///
/// Six anchors rather than a saved offset: an anchor survives a rotation and a
/// device change, where a raw offset would end up off-screen or under a system
/// bar. Dragging is free and separate — it moves the bubble for this session
/// only, and the anchor is what it returns to on the next launch.
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
