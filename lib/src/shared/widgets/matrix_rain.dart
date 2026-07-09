import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../debug_strings.dart';

/// Full-screen "Matrix" digital-rain flourish (green falling digits) shown for
/// a couple of seconds to dramatise a role switch. Use [MatrixRain.show].
class MatrixRain {
  MatrixRain._();

  /// Inserts the rain over the root overlay, with [label] (e.g. the new role)
  /// glowing in the centre, then removes itself after [duration].
  static void show(
    BuildContext context, {
    required String label,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late OverlayEntry entry;
    var removed = false;
    entry = OverlayEntry(
      builder: (_) => _MatrixRainOverlay(
        label: label,
        duration: duration,
        onComplete: () {
          if (removed) return;
          removed = true;
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _MatrixRainOverlay extends StatefulWidget {
  final String label;
  final Duration duration;
  final VoidCallback onComplete;

  const _MatrixRainOverlay({
    required this.label,
    required this.duration,
    required this.onComplete,
  });

  @override
  State<_MatrixRainOverlay> createState() => _MatrixRainOverlayState();
}

class _MatrixRainOverlayState extends State<_MatrixRainOverlay>
    with SingleTickerProviderStateMixin {
  static const double _cell = 13;

  final Random _rng = Random();
  late final Ticker _ticker;

  Duration _last = Duration.zero;
  double _elapsedMs = 0;
  double _opacity = 0;

  // Per-column state, (re)built when the column count changes.
  List<double> _heads = [];
  List<double> _speeds = [];
  List<int> _lengths = [];
  List<List<int>> _grid = []; // [column][row] -> digit 0..9
  int _cols = 0;
  int _rows = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ensureColumns(Size size) {
    final cols = (size.width / _cell).ceil();
    final rows = (size.height / _cell).ceil() + 2;
    if (cols == _cols && rows == _rows) return;
    _cols = cols;
    _rows = rows;
    _heads = List.generate(cols, (_) => -_rng.nextInt(rows).toDouble());
    _speeds = List.generate(cols, (_) => 14 + _rng.nextInt(22).toDouble());
    _lengths = List.generate(cols, (_) => 8 + _rng.nextInt(12));
    _grid = List.generate(
      cols,
      (_) => List.generate(rows, (_) => _rng.nextInt(10)),
    );
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _elapsedMs = elapsed.inMilliseconds.toDouble();

    // Advance each column's head and refresh the digit it lands on.
    for (var c = 0; c < _cols; c++) {
      _heads[c] += _speeds[c] * dt;
      if (_heads[c] - _lengths[c] > _rows) {
        _heads[c] = -_rng.nextInt(_rows ~/ 2 + 1).toDouble();
        _speeds[c] = 14 + _rng.nextInt(22).toDouble();
        _lengths[c] = 8 + _rng.nextInt(12);
      }
      final row = _heads[c].floor();
      if (row >= 0 && row < _rows) _grid[c][row] = _rng.nextInt(10);
    }

    // Fade in over the first 300ms, hold, fade out over the last 450ms.
    final total = widget.duration.inMilliseconds;
    final fadeIn = (_elapsedMs / 300).clamp(0.0, 1.0);
    final fadeOut = ((total - _elapsedMs) / 450).clamp(0.0, 1.0);
    _opacity = (fadeIn * fadeOut).clamp(0.0, 1.0);

    if (_elapsedMs >= total) {
      _ticker.stop();
      widget.onComplete();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _ensureColumns(size);

    // Label glows in shortly after the rain starts.
    final labelOpacity = ((_elapsedMs - 350) / 450).clamp(0.0, 1.0) * _opacity;

    return IgnorePointer(
      // Transparent Material gives the labels a proper DefaultTextStyle, so
      // they don't render with the framework's debug yellow underline.
      child: Material(
        type: MaterialType.transparency,
        child: Opacity(
          opacity: _opacity,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RainPainter(
                    heads: _heads,
                    lengths: _lengths,
                    grid: _grid,
                    cell: _cell,
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: labelOpacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: Color(0xFFD8FFD0),
                          shadows: [
                            Shadow(color: Color(0xFF00FF66), blurRadius: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        DebugStrings.matrixAccessMode,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          letterSpacing: 6,
                          color: Color(0xFF31D966),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  final List<double> heads;
  final List<int> lengths;
  final List<List<int>> grid;
  final double cell;

  _RainPainter({
    required this.heads,
    required this.lengths,
    required this.grid,
    required this.cell,
  });

  static const Color _head = Color(0xFFE6FFE0);
  static const Color _tail = Color(0xFF22DD66);

  final TextPainter _tp = TextPainter(textDirection: TextDirection.ltr);

  @override
  void paint(Canvas canvas, Size size) {
    // Dark, slightly green-tinted backdrop.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xF2010A04),
    );

    final fontSize = cell * 0.82;
    for (var c = 0; c < heads.length; c++) {
      final headRow = heads[c].floor();
      final len = lengths[c];
      for (var k = 0; k < len; k++) {
        final row = headRow - k;
        if (row < 0 || row >= grid[c].length) continue;
        final isHead = k == 0;
        final alpha = isHead ? 1.0 : (1 - k / len).clamp(0.0, 1.0);
        final color = (isHead ? _head : _tail).withValues(alpha: alpha);
        _tp.text = TextSpan(
          text: '${grid[c][row]}',
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: 'monospace',
            fontWeight: isHead ? FontWeight.w700 : FontWeight.w400,
          ),
        );
        _tp.layout();
        _tp.paint(canvas, Offset(c * cell, row * cell));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => true;
}
