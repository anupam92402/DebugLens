/// The six `BlocObserver` lifecycle hooks, captured by [DebugLensBlocObserver].
enum BlocActionKind { create, event, change, transition, error, close }

/// One captured BlocObserver event.
class BlocEvent {
  /// Monotonic insertion order (stable across ring-buffer trims).
  final int sequence;
  final BlocActionKind kind;

  /// `bloc.runtimeType.toString()`, e.g. `'AuthBloc'`.
  final String blocName;
  final DateTime time;

  /// Event `toString()` for [BlocActionKind.event] / [transition].
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
