import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/debug_theme.dart';
import 'debug_widgets.dart';

/// Lightweight, dependency-free toast for DebugLens screens.
///
/// Uses an [OverlayEntry] inserted into the root [Overlay], so it works
/// from any screen below `DebugLens.wrap` without a [Scaffold] in the
/// immediate ancestor chain (something `ScaffoldMessenger.showSnackBar`
/// can't guarantee inside the panel's nested navigator).
///
/// Only one toast is visible at a time — calling [show] while another is
/// active replaces it. Auto-dismisses after [duration].
class DebugToast {
  DebugToast._();

  static OverlayEntry? _current;
  static Timer? _hideTimer;

  /// Pops a brief toast over [context]. Returns immediately — the toast
  /// schedules its own removal.
  ///
  /// [duration] defaults to 1.5s, matching the longest of the SnackBars
  /// this helper replaces.
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismiss();

    final entry = OverlayEntry(
      builder: (_) => _ToastBubble(message: message),
    );
    _current = entry;
    overlay.insert(entry);

    _hideTimer = Timer(duration, _dismiss);
  }

  /// Immediately removes any visible toast. Safe to call when none exists.
  static void _dismiss() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _current?.remove();
    _current = null;
  }
}

/// Visual layer of the toast. Stateful so it can animate in/out before the
/// OverlayEntry is removed.
class _ToastBubble extends StatefulWidget {
  final String message;

  const _ToastBubble({required this.message});

  @override
  State<_ToastBubble> createState() => _ToastBubbleState();
}

class _ToastBubbleState extends State<_ToastBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  )..forward();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Lift the toast above any keyboard or system inset.
    final bottomInset =
        media.viewInsets.bottom + media.padding.bottom + 64;

    return Positioned(
      left: 24,
      right: 24,
      bottom: bottomInset,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _ctl,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(parent: _ctl, curve: Curves.easeOut),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: DebugPalette.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DebugPalette.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: monoStyle(size: 12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
