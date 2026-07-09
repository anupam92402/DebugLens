import '../core/debug_lens_logger.dart';

/// Plain-text serializers for [DebugLogRecord] used by the Logs screen
/// (bulk share / export) and Log detail screen (single-record copy).
///
/// Pure data → string; no UI imports. Single source of truth so a record
/// copied from the detail screen looks identical to the same record in a
/// shared bundle.
class LogSerializer {
  LogSerializer._();

  /// One log record on one line (plus indented error / stack blocks when
  /// present). The level is padded to 5 chars so columns line up across
  /// multiple records.
  ///
  /// Example:
  /// ```
  /// [2026-05-28T14:32:01.789] ERROR [payment] Caught demo failure
  ///   error: Bad state: Demo error from button
  ///   stack:
  ///     #0 HomeScreen.build...
  /// ```
  static String formatRecord(DebugLogRecord r) {
    final buf = StringBuffer()
      ..writeln(
        '[${r.time.toIso8601String()}] '
        '${r.level.name.toUpperCase().padRight(5)} '
        '[${_tag(r)}] '
        '${r.message}',
      );
    if (r.error != null) buf.writeln('  error: ${r.error}');
    if (r.stackTrace != null) {
      buf.writeln('  stack:');
      for (final line in r.stackTrace!.split('\n')) {
        if (line.trim().isEmpty) continue;
        buf.writeln('    $line');
      }
    }
    return buf.toString();
  }

  /// Full export bundle for the Share button on the Logs screen — header
  /// block + one [formatRecord] per row.
  static String formatBundle(List<DebugLogRecord> records) {
    final buf = StringBuffer()
      ..writeln('DebugLens log export')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Records: ${records.length}')
      ..writeln('=' * 60);
    for (final r in records) {
      buf.write(formatRecord(r));
    }
    return buf.toString();
  }

  /// Tag rendered in square brackets — falls back to a source-derived label
  /// when no explicit `name` was provided.
  static String _tag(DebugLogRecord r) =>
      r.name ?? (r.source == DebugLogSource.console ? 'console' : 'log');
}
