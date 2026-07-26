import 'dart:convert';

import '../../../shared/debug_constants.dart';
import '../../storage/data/debug_shared_prefs_source.dart';
import '../domain/dash_item.dart';

/// Persists the dashboard's tile order — the one piece of panel layout the user
/// arranges themselves.
///
/// Stored as the ordered list of **routes**, not indices: a route survives
/// tiles being added, removed or reshuffled in a later version of the package,
/// where a saved index would silently point at the wrong tile.
class DashOrderStore {
  DashOrderStore._();

  /// [all] in the saved order. Saved routes come first, in the order they were
  /// left in; tiles the save has never seen (added in a later version) keep
  /// their declared order and go at the end; saved routes that no longer exist
  /// are dropped. Returns [all] unchanged when nothing is saved yet.
  static Future<List<DashItem>> ordered(List<DashItem> all) async {
    final saved = await _readOrder();
    if (saved.isEmpty) return all;

    final byRoute = {for (final item in all) item.route: item};
    final ordered = <DashItem>[];
    for (final route in saved) {
      // Removing as we go leaves `byRoute` holding exactly the unsaved tiles.
      final item = byRoute.remove(route);
      if (item != null) ordered.add(item);
    }
    ordered.addAll(all.where((item) => byRoute.containsKey(item.route)));
    return ordered;
  }

  static Future<void> save(List<DashItem> items) =>
      DebugLensSharedPrefs.setString(
        DebugConstants.dashboardOrderPrefsKey,
        jsonEncode([for (final item in items) item.route]),
      );

  static Future<List<String>> _readOrder() async {
    final raw = await DebugLensSharedPrefs.getString(
      DebugConstants.dashboardOrderPrefsKey,
    );
    if (raw == null || raw.isEmpty) return const [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      /// Unreadable (hand-edited, or written by an older shape) — fall back to
      /// the declared order rather than failing the screen.
      return const [];
    }
  }
}
