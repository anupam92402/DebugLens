// Time formatters shared by every DebugLens screen.
//
// Kept in `util/` (not `widgets/`) because the format produces plain
// strings — no widgets, no Flutter dependency — which means it can be
// reused by serializers, exporters, and tests without dragging in UI.

/// Two-digit zero-padded helper used for clock formatting.
String _pad(int n) => n.toString().padLeft(2, '0');

/// Returns a fixed-width `HH:MM:SS` clock string for [t].
///
/// Used as the right-hand timestamp on most list rows. Stable width keeps
/// the column from wobbling as the seconds digit changes.
String formatClock(DateTime t) =>
    '${_pad(t.hour)}:${_pad(t.minute)}:${_pad(t.second)}';
