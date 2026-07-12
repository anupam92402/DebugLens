import 'bloc_event.dart';

/// A [BlocEvent] paired with its 1-based position in the visible list, so the
/// feed shows contiguous badge numbers independent of the event's global
/// sequence.
class NumberedBlocEvent {
  const NumberedBlocEvent(this.event, this.number);

  final BlocEvent event;
  final int number;
}
