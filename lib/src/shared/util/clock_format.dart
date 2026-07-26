/// Plain-string time formatters used across DebugLens.
class ClockFormat {
  ClockFormat._();

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// Fixed-width `HH:MM:SS` clock string for [t]. Stable width keeps list
  /// columns from wobbling as the seconds digit changes.
  static String clock(DateTime t) =>
      '${_pad(t.hour)}:${_pad(t.minute)}:${_pad(t.second)}';

  /// Compact elapsed time for a gap between two events, in seconds to one
  /// decimal — `0.2s`, `2.5s`. Sub-second gaps stay in seconds rather than
  /// switching to milliseconds, so a column of gaps is directly comparable.
  /// Past a minute it steps up to `1m 12s` / `2h 5m`, which stays readable
  /// where `4320.0s` would not.
  static String gap(Duration d) {
    if (d.inSeconds < 60) {
      return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
    if (d.inMinutes < 60) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }

  /// Readable `YYYY-MM-DD HH:MM:SS` string for [t].
  static String dateTime(DateTime t) =>
      '${t.year}-${_pad(t.month)}-${_pad(t.day)} '
      '${_pad(t.hour)}:${_pad(t.minute)}:${_pad(t.second)}';
}
