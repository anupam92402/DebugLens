/// Lifecycle hooks captured by [DebugLensBlocObserver].
///
/// Mirrors the six callbacks exposed by `bloc`'s `BlocObserver` so a glance
/// at the Bloc screen tells you exactly what happened.
enum BlocActionKind { create, event, change, transition, error, close }

/// One captured BlocObserver event. Append-only — see [DebugStore.blocEvents].
class BlocEvent {
  /// Monotonic insertion order. Stable even after the ring buffer trims the
  /// oldest entries, so deep links from logs/screenshots still resolve.
  final int sequence;
  final BlocActionKind kind;

  /// `bloc.runtimeType.toString()` — e.g. `'CounterCubit'`, `'AuthBloc'`.
  final String blocName;
  final DateTime time;

  /// Event object for [BlocActionKind.event] and [BlocActionKind.transition].
  /// `toString()` snapshot to decouple from mutable app state.
  final String? event;

  /// State before the change. Set for [change] / [transition].
  final String? currentState;

  /// State after the change. Set for [change] / [transition].
  final String? nextState;

  /// `toString()` of the thrown object. Set for [error].
  final String? error;

  /// Stack trace as text. Set for [error].
  final String? stackTrace;

  const BlocEvent({
    required this.sequence,
    required this.kind,
    required this.blocName,
    required this.time,
    this.event,
    this.currentState,
    this.nextState,
    this.error,
    this.stackTrace,
  });

  /// Short word for the action chip — matches the chip label in the UI.
  String get kindLabel => kind.name;
}
