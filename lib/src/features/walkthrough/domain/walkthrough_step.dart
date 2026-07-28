import 'package:flutter/widgets.dart';

/// One stop on the first-run tour: what to say, and optionally what to point at.
@immutable
class WalkthroughStep {
  final String title;
  final String body;

  /// The widget to spotlight. Null — or a key whose widget isn't currently on
  /// screen — shows the caption centred with nothing cut out, so a step never
  /// points at empty space.
  final GlobalKey? target;

  const WalkthroughStep({required this.title, required this.body, this.target});

  /// The target's rect in global coordinates, or null when it isn't laid out.
  Rect? rect() {
    final box = target?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
