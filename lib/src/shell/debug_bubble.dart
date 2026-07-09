import 'package:flutter/material.dart';

/// A draggable, edge-floating button that opens the DebugLens panel.
///
/// Rendered in a full-screen [Stack] but only the button hit-tests, so the
/// host app remains fully interactive around it.
class DebugBubble extends StatefulWidget {
  final VoidCallback onTap;

  const DebugBubble({super.key, required this.onTap});

  @override
  State<DebugBubble> createState() => _DebugBubbleState();
}

class _DebugBubbleState extends State<DebugBubble> {
  static const double _size = 48;
  Offset? _pos;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final pos = _pos ?? Offset(16, screen.height - _size - 64);

    return Stack(
      children: [
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: GestureDetector(
            onTap: widget.onTap,
            onPanUpdate: (d) {
              setState(() {
                _pos = Offset(
                  (pos.dx + d.delta.dx).clamp(0.0, screen.width - _size),
                  (pos.dy + d.delta.dy).clamp(0.0, screen.height - _size),
                );
              });
            },
            child: Material(
              color: Color(0xffFFFFFF),
              shape: const CircleBorder(),
              elevation: 6,
              child: const SizedBox(
                width: _size,
                height: _size,
                child: Icon(
                  Icons.flutter_dash_sharp,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
