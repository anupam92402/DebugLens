/// A retention limit the panel keeps — one per captured feed.
///
/// Each is a ring-buffer cap: once the feed holds this many records the oldest
/// is dropped. The [fallback] values are the caps the package shipped with, so
/// a fresh install behaves exactly as before anything is edited.
enum DebugLimit {
  network(label: 'Network', fallback: 250),
  logs(label: 'Logs', fallback: 1000),
  notifications(label: 'Notifications', fallback: 200),
  deeplinks(label: 'Deep-links', fallback: 200),
  bloc(label: 'Bloc', fallback: 200),
  navigation(label: 'Navigation', fallback: 500),
  crashes(label: 'Crashes', fallback: 100),
  analytics(label: 'Analytics', fallback: 100),
  traces(label: 'Traces', fallback: 100);

  const DebugLimit({required this.label, required this.fallback});

  /// Row title in the limits sheet.
  final String label;

  /// Applied when nothing has been set, and what Reset restores.
  final int fallback;

  /// Bounds the edit dialog enforces. The floor keeps a feed useful; the
  /// ceiling keeps a long session from holding an unbounded amount of captured
  /// bodies and stack traces in memory.
  static const int min = 50;
  static const int max = 5000;

  /// Granularity of the edit slider. Every shipped [fallback] is a multiple of
  /// it, so opening the dialog on an untouched limit lands exactly on a notch.
  static const int step = 50;

  /// Notches between [min] and [max], for `Slider.divisions`.
  static int get divisions => (max - min) ~/ step;

  /// Whether [value] is inside [min]–[max]. The dialog blocks saving otherwise,
  /// so a stored limit is always in range.
  static bool accepts(int value) => value >= min && value <= max;
}
