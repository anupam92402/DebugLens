import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/debug_constants.dart';
import '../shell/debug_routes.dart';

/// Access role for the DebugLens panel.
///
/// - [tester] (default): can only open the screens a developer has granted.
/// - [developer]: can open every screen.
enum DebugRole { tester, developer }

/// Holds the current [DebugRole] and the set of routes a tester may open, both
/// persisted with `shared_preferences` so the choices survive across launches
/// and reset only when app data is cleared. Default is [DebugRole.tester] with
/// Network as the single granted route.
class DebugRoleController extends ChangeNotifier {
  DebugRole _role = DebugRole.tester;

  /// Routes a tester may open. Developers ignore this entirely.
  Set<String> _testerRoutes = {DebugRoutes.network};

  /// Whether the tester role is available at all. Turning it off doesn't change
  /// the current role — it closes the door, so a developer can no longer step
  /// down into it.
  bool _testerEnabled = true;

  DebugRole get role => _role;
  bool get isDeveloper => _role == DebugRole.developer;

  /// Unmodifiable view — change it through [setTesterRoutes], which persists.
  Set<String> get testerRoutes => Set.unmodifiable(_testerRoutes);

  bool get testerEnabled => _testerEnabled;

  /// Whether [route] is open to the current role.
  bool canOpen(String route) => isDeveloper || _testerRoutes.contains(route);

  /// Whether [toggle] would actually change anything.
  ///
  /// False only when a developer would be stepping down into a tester role that
  /// is switched off. Callers check this *before* starting any switch
  /// animation, so a long-press that can't land anywhere plays nothing at all.
  bool get canToggle => !isDeveloper || _testerEnabled;

  DebugRoleController() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(DebugConstants.rolePrefsKey) ==
          DebugRole.developer.name) {
        _role = DebugRole.developer;
      }
      _testerEnabled =
          prefs.getString(DebugConstants.testerEnabledPrefsKey) !=
          DebugConstants.falseValue;
      final raw = prefs.getString(DebugConstants.testerRoutesPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        // An empty saved set is honoured: a developer may deliberately have
        // granted a tester nothing at all.
        _testerRoutes = Set<String>.from(jsonDecode(raw) as List);
      }
      notifyListeners();
    } catch (_) {
      // Storage unavailable or unreadable — keep the defaults.
    }
  }

  /// Switches between tester and developer and persists the new value.
  ///
  /// There is no gate on becoming a developer: the panel only ships in builds
  /// the team controls, and a password that lived in the source protected
  /// nothing. Stepping *down* is gated on [canToggle] — with the tester role
  /// switched off there is nowhere to step down to, so this is a no-op.
  Future<void> toggle() async {
    if (!canToggle) return;
    _role = isDeveloper ? DebugRole.tester : DebugRole.developer;
    notifyListeners();
    await _persist(DebugConstants.rolePrefsKey, _role.name);
  }

  /// Enables or disables the tester role.
  ///
  /// Deliberately does **not** switch roles: a developer turning it on stays a
  /// developer. Turning it off while already a tester promotes back to
  /// developer, since the current role would otherwise be one that no longer
  /// exists.
  Future<void> setTesterEnabled(bool enabled) async {
    if (_testerEnabled == enabled) return;
    _testerEnabled = enabled;
    if (!enabled && !isDeveloper) {
      _role = DebugRole.developer;
      await _persist(DebugConstants.rolePrefsKey, _role.name);
    }
    notifyListeners();
    await _persist(
      DebugConstants.testerEnabledPrefsKey,
      enabled ? DebugConstants.trueValue : DebugConstants.falseValue,
    );
  }

  /// Replaces the routes a tester may open, and persists them.
  Future<void> setTesterRoutes(Set<String> routes) async {
    _testerRoutes = {...routes};
    notifyListeners();
    await _persist(
      DebugConstants.testerRoutesPrefsKey,
      jsonEncode(_testerRoutes.toList()),
    );
  }

  Future<void> _persist(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      // Persistence failed — the in-memory value still applies this session.
    }
  }
}
