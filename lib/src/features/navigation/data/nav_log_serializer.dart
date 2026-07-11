import '../../../shared/debug_constants.dart';
import '../../../shared/util/clock_format.dart';
import '../../../shell/debug_routes.dart';
import '../domain/nav_event.dart';

/// Formats captured navigation data into the plain-text `navigation` section
/// fed to the log-file share. Pure — no Flutter/UI — so the screen stays free
/// of formatting logic and this stays easy to unit-test.
class NavLogSerializer {
  NavLogSerializer._();

  static String dump(
    List<NavEvent> events,
    Map<String, List<String>> stacks, {
    bool hideDebugLens = false,
  }) {
    bool keep(String name) =>
        !hideDebugLens || !name.startsWith(DebugRoutes.prefix);
    final visible = events.where((e) => keep(e.routeName)).toList();

    final b = StringBuffer()..writeln('Events (${visible.length}):');
    for (final e in visible) {
      b.writeln(
        '#${e.sequence} ${e.actionLabel} ${e.kindLabel} '
        '${e.previousRoute ?? DebugConstants.emptyValue} -> ${e.routeName} '
        '[${e.navigator}] ${formatClock(e.time)}',
      );
    }
    for (final entry in stacks.entries) {
      final rows = entry.value.where(keep).toList();
      if (rows.isEmpty) continue;
      b
        ..writeln()
        ..writeln('Stack (${entry.key}):');
      for (var i = rows.length - 1; i >= 0; i--) {
        b.writeln('${i + 1} ${rows[i]}');
      }
    }
    return b.toString().trimRight();
  }
}
