// Barrel for the shared widget kit — each widget now lives in its own file.
// Screens keep importing `widgets/debug_widgets.dart` and get everything
// (the widgets, monoStyle/formatAgo, and the re-exported formatClock).
export '../util/clock_format.dart' show formatClock;
export 'debug_search_field.dart';
export 'empty_state.dart';
export 'kv_row.dart';
export 'section_card.dart';
export 'status_chip.dart';
export 'text_styles.dart';
