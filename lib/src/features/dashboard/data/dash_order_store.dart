import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../shared/debug_constants.dart';
import '../../storage/data/debug_shared_prefs_source.dart';
import '../domain/dash_item.dart';

/// Persists the dashboard's tile order — the one piece of panel layout the user
/// arranges themselves.
///
/// Stored as the ordered list of **routes**, not indices: a route survives
/// tiles being added, removed or reshuffled in a later version of the package,
/// where a saved index would silently point at the wrong tile.
///
/// A `ChangeNotifier` so the dashboard re-renders when the order changes from
/// somewhere else — [reset] is called from Settings, with the dashboard still
/// mounted underneath.
class DashOrderStore extends ChangeNotifier {
  DashOrderStore._();

  static final DashOrderStore instance = DashOrderStore._();

  /// The saved order, as routes. Empty means "as declared".
  List<String> _order = const [];

  /// Whether the order has been rearranged from the declared one.
  bool get isCustom => _order.isNotEmpty;

  /// Loads the saved order. Called once from `DebugLens.wrap`.
  Future<void> restore() async {
    final raw = await DebugLensSharedPrefs.getString(
      DebugConstants.dashboardOrderPrefsKey,
    );
    if (raw == null || raw.isEmpty) return;
    try {
      _order = List<String>.from(jsonDecode(raw) as List);
      notifyListeners();
    } catch (_) {
      /// Unreadable (hand-edited, or written by an older shape) — fall back to
      /// the declared order rather than failing the screen.
      _order = const [];
    }
  }

  /// [all] in the saved order. Saved routes come first, in the order they were
  /// left in; tiles the save has never seen (added in a later version) keep
  /// their declared order and go at the end; saved routes that no longer exist
  /// are dropped. Returns [all] unchanged when nothing is saved.
  List<DashItem> ordered(List<DashItem> all) {
    if (_order.isEmpty) return all;

    final byRoute = {for (final item in all) item.route: item};
    final ordered = <DashItem>[];
    for (final route in _order) {
      // Removing as we go leaves `byRoute` holding exactly the unsaved tiles.
      final item = byRoute.remove(route);
      if (item != null) ordered.add(item);
    }
    ordered.addAll(all.where((item) => byRoute.containsKey(item.route)));
    return ordered;
  }

  Future<void> save(List<DashItem> items) async {
    _order = [for (final item in items) item.route];
    notifyListeners();
    await _write();
  }

  /// Forgets the arrangement, putting the tiles back in declared order.
  Future<void> reset() async {
    if (_order.isEmpty) return;
    _order = const [];
    notifyListeners();
    await _write();
  }

  Future<void> _write() => DebugLensSharedPrefs.setString(
    DebugConstants.dashboardOrderPrefsKey,
    _order.isEmpty ? null : jsonEncode(_order),
  );
}
