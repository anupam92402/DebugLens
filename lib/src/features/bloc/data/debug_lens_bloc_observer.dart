import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../logs/data/debug_lens_logger.dart';
import '../../../core/debug_store.dart';
import '../domain/bloc_event.dart';

/// A [BlocObserver] that routes every Bloc/Cubit lifecycle event into:
///
/// 1. The Bloc screen (via [DebugStore.recordBlocEvent]) — structured rows
///    with expandable details (current/next state, event payload, error,
///    stack).
/// 2. The Logs screen (via [DebugLensLogger]) — a one-line summary tagged
///    `bloc.<RuntimeType>` so search/grep across all logs still works.
///
/// Install once at app startup:
///
/// ```dart
/// void main() {
///   Bloc.observer = DebugLensBlocObserver();
///   runApp(const MyApp());
/// }
/// ```
///
/// Adapted from `AppBlocObserver` in `we_core` — same hook coverage, but
/// logs plain messages (the colour palette is applied by DebugLensLogger
/// rather than embedded as ANSI escape codes in the message text).
class DebugLensBlocObserver extends BlocObserver {
  /// When `false`, the observer still runs (so the underlying super-calls
  /// happen) but emits no log entries / store updates — useful for release
  /// builds or for quieting a noisy bloc during a session.
  final bool showLogs;

  final DebugStore _store;

  DebugLensBlocObserver({this.showLogs = true, DebugStore? store})
    : _store = store ?? DebugStore.instance;

  /// Tag used in the Logs screen so a user can grep by bloc class —
  /// e.g. searching `bloc.AuthCubit` narrows to a single bloc's stream.
  String _name(BlocBase<dynamic> bloc) => 'bloc.${bloc.runtimeType}';

  /// Schedules [body] to run on the next microtask so any synchronous
  /// constructor / build chain that triggered the callback can finish first.
  ///
  /// Why this exists: `BlocBase`'s constructor calls `observer.onCreate(this)`
  /// synchronously. If `onCreate` then mutates a `ChangeNotifier` and notifies
  /// while a `BlocProvider.create()` callback is mid-flight, Provider's
  /// debug-introspection tries to read the not-yet-assigned value and crashes
  /// with `type 'Null' is not a subtype of type ComponentBloc`. Deferring to a
  /// microtask lets the synchronous chain finish (Provider assigns its value)
  /// before we update the store / logger.
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
