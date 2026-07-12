import '../../../shared/debug_constants.dart';
import '../../../shared/util/clock_format.dart';
import '../domain/bloc_event.dart';

/// Formats captured Bloc events into the plain-text share section. Pure — no UI.
class BlocLogSerializer {
  BlocLogSerializer._();

  static String dump(List<BlocEvent> events) {
    final b = StringBuffer()..writeln('Bloc events (${events.length}):');
    for (final e in events) {
      b.writeln(
        '#${e.sequence} ${e.kindLabel} ${e.blocName} '
        '${ClockFormat.clock(e.time)}',
      );
      if (e.event != null) b.writeln('  event: ${e.event}');
      if (e.currentState != null || e.nextState != null) {
        b.writeln(
          '  state: ${e.currentState ?? DebugConstants.unknownValue} -> '
          '${e.nextState ?? DebugConstants.unknownValue}',
        );
      }
      if (e.error != null) b.writeln('  error: ${e.error}');
      if (e.stackTrace != null) b.writeln('  stack: ${e.stackTrace}');
    }
    return b.toString().trimRight();
  }
}
