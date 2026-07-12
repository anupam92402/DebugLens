/// Plain-string time formatters used across DebugLens.
class ClockFormat {
  ClockFormat._();

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// Fixed-width `HH:MM:SS` clock string for [t]. Stable width keeps list
  /// columns from wobbling as the seconds digit changes.
  static String clock(DateTime t) =>
      '${_pad(t.hour)}:${_pad(t.minute)}:${_pad(t.second)}';

  /// Readable `YYYY-MM-DD HH:MM:SS` string for [t].
  static String dateTime(DateTime t) =>
      '${t.year}-${_pad(t.month)}-${_pad(t.day)} '
      '${_pad(t.hour)}:${_pad(t.minute)}:${_pad(t.second)}';
}
