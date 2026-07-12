import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../logs/data/debug_lens_logger.dart';
import '../../../core/debug_store.dart';
import '../domain/bloc_event.dart';

/// [BlocObserver] that routes every Bloc/Cubit lifecycle event into the Bloc
/// screen (via [DebugStore.recordBlocEvent]) and the Logs feed (tagged
/// `bloc.<RuntimeType>`). Install once: `Bloc.observer = DebugLensBlocObserver()`.
class DebugLensBlocObserver extends BlocObserver {
  /// When `false`, the super-calls still run but no store/log entries are
  /// emitted — for quieting capture in release or during a noisy session.
  final bool showLogs;

  final DebugStore _store;

  DebugLensBlocObserver({this.showLogs = true, DebugStore? store})
    : _store = store ?? DebugStore.instance;

  /// Logs tag for grepping by bloc class, e.g. `bloc.AuthCubit`.
  String _name(BlocBase<dynamic> bloc) => 'bloc.${bloc.runtimeType}';

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
      DebugLensLogger().d('created', name: tag);
    });
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (!showLogs) return;
    final blocName = bloc.runtimeType.toString();
    final tag = _name(bloc);
    final eventStr = event?.toString();
    _defer(() {
      _store.recordBlocEvent(
        kind: BlocActionKind.event,
        blocName: blocName,
        event: eventStr,
      );
      DebugLensLogger().d('event: $eventStr', name: tag);
    });
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (!showLogs) return;
    final blocName = bloc.runtimeType.toString();
    final tag = _name(bloc);
    final current = change.currentState?.toString();
    final next = change.nextState?.toString();
    _defer(() {
      _store.recordBlocEvent(
        kind: BlocActionKind.change,
        blocName: blocName,
        currentState: current,
        nextState: next,
      );
      DebugLensLogger().d('change: $current → $next', name: tag);
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
    final eventStr = transition.event?.toString();
    final current = transition.currentState?.toString();
    final next = transition.nextState?.toString();
    _defer(() {
      _store.recordBlocEvent(
        kind: BlocActionKind.transition,
        blocName: blocName,
        event: eventStr,
        currentState: current,
        nextState: next,
      );
      DebugLensLogger().d(
        'transition: $current → $next (event: $eventStr)',
        name: tag,
      );
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
        error: error.toString(),
        stackTrace: stackTrace.toString(),
      );
      DebugLensLogger().e(
        'error: $error',
        name: tag,
        error: error,
        stackTrace: stackTrace,
      );
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
      DebugLensLogger().d('closed', name: tag);
    });
  }
}
