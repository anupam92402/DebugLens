import 'package:flutter/material.dart';

import '../features/settings/data/bubble_store.dart';
import '../features/settings/domain/bubble_style.dart';

/// A draggable, edge-floating button that opens the DebugLens panel.
///
/// Rendered in a full-screen [Stack] but only the button hit-tests, so the
/// host app remains fully interactive around it.
///
/// Two ways to move it, deliberately different in how long they last:
///
/// * **Drag** — free, anywhere on screen, and it stays where you drop it. Good
///   for nudging it off whatever you are looking at right now. Not saved.
/// * **The anchor in Settings** — one of [BubbleCorner]'s six positions, saved
///   and restored. This is where the bubble starts every launch, so a drag is
///   undone by a restart.
class DebugBubble extends StatefulWidget {
  final VoidCallback onTap;

  const DebugBubble({super.key, required this.onTap});

  @override
  State<DebugBubble> createState() => _DebugBubbleState();
}

class _DebugBubbleState extends State<DebugBubble> {
  static const double _size = 48;

  /// Where the last drag left it; null means "follow the saved anchor".
  ///
  /// A notifier rather than plain state so a drag rebuilds only the
  /// [Positioned] — the button itself is passed through as a stable `child` and
  /// never rebuilt while the finger moves, which is what keeps the drag smooth.
  final ValueNotifier<Offset?> _dragged = ValueNotifier<Offset?>(null);

  @override
  void initState() {
    super.initState();
    BubbleStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    BubbleStore.instance.removeListener(_onStoreChanged);
    _dragged.dispose();
    super.dispose();
  }

  /// Picking an anchor in Settings has to win over an earlier drag, or the
  /// bubble would sit where it was dropped and the picker would look broken.
  /// The `setState` is for the icon, which may have changed in the same edit.
  void _onStoreChanged() {
    _dragged.value = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = BubbleStore.instance;
    final media = MediaQuery.of(context);
    final screen = media.size;
    final anchored = store.corner.offsetIn(screen, media.padding, _size);

    return Stack(
      children: [
        ValueListenableBuilder<Offset?>(
          valueListenable: _dragged,
          // Not rebuilt on a position change — only the Positioned above it is.
          child: GestureDetector(
            onTap: widget.onTap,
            onPanUpdate: (d) {
              // Read the notifier, not a value captured by this build: pan
              // events can arrive faster than frames, and accumulating onto a
              // stale offset drops movement and makes the drag stutter.
              final base = _dragged.value ?? anchored;
              _dragged.value = Offset(
                (base.dx + d.delta.dx).clamp(0.0, screen.width - _size),
                (base.dy + d.delta.dy).clamp(0.0, screen.height - _size),
              );
            },
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 6,
              child: SizedBox(
                width: _size,
                height: _size,
                child: Center(
                  child: store.icon.glyph(size: 24, color: Colors.black),
                ),
              ),
            ),
          ),
          builder: (context, dragged, child) {
            final pos = dragged ?? anchored;
            return Positioned(left: pos.dx, top: pos.dy, child: child!);
          },
        ),
      ],
    );
  }
}
