import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../domain/walkthrough_step.dart';

/// The first-run tour: a dimmed screen with a hole punched around whatever the
/// current step points at, and a caption card beside it.
class WalkthroughOverlay extends StatefulWidget {
  final List<WalkthroughStep> steps;
  final VoidCallback onFinish;

  const WalkthroughOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
  });

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay> {
  int _index = 0;

  /// The dashboard's own accent, so the tour reads as part of the panel rather
  /// than as a stock Material dialog dropped on top of it.
  static const Color _accent = DebugColors.base;

  /// Breathing room between the hole and the highlighted widget's own bounds.
  static const double _padding = 8;

  /// Gap between the hole and the caption card.
  static const double _gap = 14;

  bool get _isLast => _index == widget.steps.length - 1;

  void _next() {
    if (_isLast) {
      widget.onFinish();
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final media = MediaQuery.of(context);
    final hole = step.rect()?.inflate(_padding);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Absorbs every tap, so nothing behind the dim reacts.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _SpotlightPainter(hole: hole, accent: _accent),
              ),
            ),
          ),
          _caption(media.size, media.padding, hole),
        ],
      ),
    );
  }

  /// Placed on whichever side of the hole has more room, and centred when this
  /// step has nothing to point at.
  Widget _caption(Size screen, EdgeInsets safeArea, Rect? hole) {
    if (hole == null) return Center(child: _card());

    final below = screen.height - hole.bottom - safeArea.bottom;
    final above = hole.top - safeArea.top;
    final preferBelow = below >= above;
    return Positioned(
      left: 0,
      right: 0,
      top: preferBelow ? hole.bottom + _gap : safeArea.top + _gap,
      bottom: preferBelow
          ? safeArea.bottom + _gap
          : screen.height - hole.top + _gap,
      child: Align(
        alignment: preferBelow ? Alignment.topCenter : Alignment.bottomCenter,
        child: SingleChildScrollView(child: _card()),
      ),
    );
  }

  Widget _card() {
    final step = widget.steps[_index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Accent bleeding in from the top-left — the same treatment the
          // dashboard tiles get, so the card belongs to the panel.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(DebugColors.surface, _accent, 0.20)!,
              DebugColors.surface,
            ],
          ),
          border: Border.all(color: _accent.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.20),
              blurRadius: 28,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dots(),
              const SizedBox(height: 12),
              Text(
                step.title,
                style: monoStyle(
                  size: 15,
                  weight: FontWeight.w700,
                  color: DebugColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step.body,
                style: monoStyle(size: 12, color: DebugColors.textMuted),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: widget.onFinish,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      DebugStrings.walkthroughSkip,
                      style: monoStyle(size: 12, color: DebugColors.textMuted),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    // Styled explicitly: the default Material lavender belongs
                    // to no part of this palette.
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _isLast
                          ? DebugStrings.walkthroughDone
                          : DebugStrings.walkthroughNext,
                      style: monoStyle(
                        size: 12,
                        weight: FontWeight.w700,
                        color: DebugColors.bg,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Progress as pills — the current step stretched, the rest dim. Reads at a
  /// glance where "2 of 3" needed reading.
  Widget _dots() {
    return Row(
      children: [
        for (var i = 0; i < widget.steps.length; i++)
          Container(
            margin: const EdgeInsets.only(right: 5),
            width: i == _index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i == _index
                  ? _accent
                  : DebugColors.textMuted.withValues(alpha: 0.30),
            ),
          ),
      ],
    );
  }
}

/// Dims everything except [hole], which is left clear and ringed in [accent].
class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final Color accent;

  const _SpotlightPainter({required this.accent, this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Rect.fromLTWH(0, 0, size.width, size.height);
    // The panel's own background, nearly opaque — so it reads as the panel
    // dimmed rather than a black sheet laid over it.
    final dim = Paint()..color = DebugColors.bg.withValues(alpha: 0.90);
    final target = hole;

    if (target == null) {
      canvas.drawRect(screen, dim);
      return;
    }

    // A difference path rather than a clear blend mode: no `saveLayer`, and it
    // composites correctly over whatever the overlay sits on.
    final rounded = RRect.fromRectAndRadius(target, const Radius.circular(14));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(screen),
        Path()..addRRect(rounded),
      ),
      dim,
    );
    // A wide translucent stroke under a crisp one, faking a glow so the
    // spotlight looks lit rather than merely outlined.
    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = accent.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.accent != accent;
}
