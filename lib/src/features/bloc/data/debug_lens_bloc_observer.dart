import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../logs/data/debug_lens_logger.dart';
import '../../logs/domain/log_origin.dart';
import '../../../core/debug_store.dart';
import '../../../shared/util/payload_budget.dart';
import '../domain/bloc_event.dart';

/// [BlocObserver] that routes every Bloc/Cubit lifecycle event into the Bloc
/// screen (via [DebugStore.recordBlocEvent]) and the Logs feed (tagged
/// `bloc.<RuntimeType>`). Install once: `Bloc.observer = DebugLensBlocObserver()`.
class DebugLensBlocObserver extends BlocObserver {
  /// When `false`, the super-calls still run but no store/log entries are
  /// emitted — for quieting capture in release or during a noisy session.
  final bool showLogs;

  final DebugStore _store;

  /// Install once: `Bloc.observer = DebugLensBlocObserver()`.
  DebugLensBlocObserver({this.showLogs = true, DebugStore? store})
    : _store = store ?? DebugStore.instance;

  /// Every state, event and error is stringified through
  /// [PayloadBudget.describe] rather than `toString()` directly. A state that
  /// carries a list or a decoded response prints megabytes, and the Bloc feed
  /// keeps two of those per change plus the same text again as a log line —
  /// a record-count cap alone does not bound that.
  ///
  /// Logs tag for grepping by bloc class, e.g. `bloc.AuthCubit`.
  String _name(BlocBase<dynamic> bloc) => 'bloc.${bloc.runtimeType}';

  /// Mirrors one event into the Logs feed, unless the user paused bloc capture
  /// from the Logs screen. The Bloc screen keeps its own record either way, so
  /// pausing here only quiets the Logs list.
  void _mirror(
    String message,
    String tag, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logger = DebugLensLogger();
    if (!logger.isCapturing(DebugLogOrigin.bloc)) return;
    if (error == null) {
      logger.d(message, name: tag);
    } else {
      logger.e(message, name: tag, error: error, stackTrace: stackTrace);
    }
  }

  /// Defers [body] to the next microtask. `onCreate` fires synchronously from
  /// `BlocBase`'s constructor; notifying the store mid-`BlocProvider.create()`
  /// crashes Provider's introspection, so we let that chain finish first.
  void _defer(void Function() body) => scheduleMicrotask(body);

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (!showLogs) return;
    final blocName = bloc.runtimeType.toString();
    final tag = _name(bloc);
    _defer(() {
      _store.recordBlocEvent(kind: BlocActionKind.create, blocName: blocName);
      _mirror('created', tag);
    });
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (!showLogs) return;
    final blocName = bloc.runtimeType.toString();
    final tag = _name(bloc);
    final eventStr = PayloadBudget.describe(event);
    _defer(() {
      _store.recordBlocEvent(
        kind: BlocActionKind.event,
        blocName: blocName,
        event: eventStr,
      );
      _mirror('event: $eventStr', tag);
    });
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (!showLogs) return;
    final blocName = bloc.runtimeType.toString();
    final tag = _name(bloc);
    final current = PayloadBudget.describe(change.currentState);
    final next = PayloadBudget.describe(change.nextState);
    _defer(() {
      _store.recordBlocEvent(
        kind: BlocActionKind.change,
        blocName: blocName,
        currentState: current,
        nextState: next,
      );
      _mirror('change: $current → $next', tag);
    });
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (!showLogs) return;
    final blocName = bloc.runtimeType.toString();
    final tag = _name(bloc);
    final eventStr = PayloadBudget.describe(transition.event);
    final current = PayloadBudget.describe(transition.currentState);
    final next = PayloadBudget.describe(transition.nextState);
    _defer(() {
      _store.recordBlocEvent(
        kind: BlocActionKind.transition,
        blocName: blocName,
        event: eventStr,
        currentState: current,
        nextState: next,
      );
      _mirror('transition: $current → $next (event: $eventStr)', tag);
    });
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (!showLogs) return;
    final blocName = bloc.runtimeType.toString();
    final tag = _name(bloc);
    _defer(() {
      _store.recordBlocEvent(
        kind: BlocActionKind.error,
        blocName: blocName,
        error: PayloadBudget.describe(error),
        stackTrace: PayloadBudget.describe(stackTrace),
      );
      _mirror('error: $error', tag, error: error, stackTrace: stackTrace);
    });
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    if (!showLogs) return;
    final blocName = bloc.runtimeType.toString();
    final tag = _name(bloc);
    _defer(() {
      _store.recordBlocEvent(kind: BlocActionKind.close, blocName: blocName);
      _mirror('closed', tag);
    });
  }
}
