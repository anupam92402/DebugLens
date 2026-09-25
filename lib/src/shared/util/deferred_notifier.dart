import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// A [ChangeNotifier] whose capture paths notify *after* the current frame
/// rather than inside it.
///
/// DebugLens records from wherever the app happens to be: a bloc transition, a
/// route push, an interceptor callback, a log line inside a `build`. Its stores
/// are handed to the panel through `Provider`, so a synchronous
/// `notifyListeners()` reaches `Element.markNeedsBuild`. Called during a build
/// that is already in progress, that trips the framework's
/// "setState() called during build" assertion, which goes to
/// `FlutterError.reportError` → the host app's `FlutterError.onError`. A host
/// that reports errors back into DebugLens (the documented way to fill the
/// Services screen) then records the error, which notifies again, which
/// asserts again — an unbounded recursion that captures one stack trace per
/// turn and exhausts the heap in seconds.
///
/// Deferring breaks that loop at the source, and coalesces a burst of records
/// into a single rebuild of the panel.
mixin DeferredNotifier on ChangeNotifier {
  late final DeferredSignal _signal = DeferredSignal(notifyListeners);

  /// Notifies listeners once the framework is safely between frames.
  ///
  /// Repeated calls before the flush collapse into one notification.
  @protected
  void scheduleNotification() => _signal.schedule();
}

/// Coalesces repeated calls to [action] into one, run between frames.
///
/// The counterpart to [DeferredNotifier] for the stores that signal through a
/// `ValueNotifier` instead of extending [ChangeNotifier]. Both exist for the
/// same reason: a capture path must never mark a widget dirty inside the build
/// that is capturing.
class DeferredSignal {
  DeferredSignal(this._action);

  final VoidCallback _action;
  bool _scheduled = false;

  /// Runs [_action] once the framework is safely between frames.
  void schedule() {
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(_flush);
  }

  void _flush() {
    final binding = SchedulerBinding.instance;
    // Microtasks can be drained mid-frame, so check before touching listeners
    // and fall through to a post-frame callback when a frame is underway.
    switch (binding.schedulerPhase) {
      case SchedulerPhase.transientCallbacks:
      case SchedulerPhase.midFrameMicrotasks:
      case SchedulerPhase.persistentCallbacks:
        binding.addPostFrameCallback((_) {
          _scheduled = false;
          _action();
        });
        // A post-frame callback only runs if another frame is scheduled; this
        // one is, because we are inside one.
        return;
      case SchedulerPhase.idle:
      case SchedulerPhase.postFrameCallbacks:
        _scheduled = false;
        _action();
    }
  }
}
