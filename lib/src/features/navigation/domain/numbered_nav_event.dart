import 'nav_event.dart';

/// A [NavEvent] paired with its 1-based position in the visible list, so the
/// Events tab can show contiguous badge numbers independent of the event's
/// global sequence.
class NumberedNavEvent {
  const NumberedNavEvent(this.event, this.number);

  final NavEvent event;
  final int number;
}
