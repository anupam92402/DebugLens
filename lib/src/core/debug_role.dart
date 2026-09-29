import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../features/storage/data/debug_shared_prefs_source.dart';
import '../shared/debug_constants.dart';
import 'debug_screen.dart';

/// Access role for the DebugLens panel.
enum DebugRole {
  /// Limited access: only the screens granted through
  /// `DebugLens.initialTesterAccess` or the Tester access sheet, and never
  /// Settings.
  tester,

  /// Full access to every panel screen, including Settings.
  developer,
}

/// Holds the current [DebugRole] and the set of routes a tester may open, both
/// persisted with `shared_preferences` so the choices survive across launches
/// and reset only when app data is cleared. Default is [DebugRole.tester] with
/// Network as the single granted route.
class DebugRoleController extends ChangeNotifier {
  /// Role a fresh install starts in — set through `DebugLens.initialRole`.
  static DebugRole initial = DebugRole.tester;

  /// Screens a tester may open on a fresh install — set through
  /// `DebugLens.initialTesterAccess`. Seeds the first launch only; once the
  /// grants have been edited on a device the saved set wins.
  static Set<DebugScreen> initialTesterAccess = {DebugScreen.network};

  /// Whether the tester role is available on a fresh install — set through
  /// `DebugLens.initialTesterEnabled`. Seeds the first launch only.
  static bool initialTesterEnabled = true;

  DebugRole _role = initial;

  /// Routes a tester may open. Developers ignore this entirely.
  Set<String> _testerRoutes = {
    for (final screen in initialTesterAccess) screen.route,
  };

  /// Whether the tester role is available at all. Turning it off doesn't change
  /// the current role — it closes the door, so a developer can no longer step
  /// down into it.
  bool _testerEnabled = initialTesterEnabled;

  bool get isDeveloper => _role == DebugRole.developer;

  /// Unmodifiable view — change it through [setTesterRoutes], which persists.
  Set<String> get testerRoutes => Set.unmodifiable(_testerRoutes);

  bool get testerEnabled => _testerEnabled;

  /// Whether [route] is open to the current role.
  bool canOpen(String route) => isDeveloper || _testerRoutes.contains(route);

  /// Whether [toggle] would actually change anything.
  bool get canToggle => !isDeveloper || _testerEnabled;

  DebugRoleController() {
    _load();
  }

  Future<void> _load() async {
    final savedRole = await DebugLensSharedPrefs.getString(
      DebugConstants.rolePrefsKey,
    );
    // Applied in both directions: with [initial] set to developer, a saved
    // tester choice has to demote, or switching down wouldn't survive a
    // relaunch.
    if (savedRole != null) {
      _role = savedRole == DebugRole.developer.name
          ? DebugRole.developer
          : DebugRole.tester;
    }
    // Only when something is saved, so `initialTesterEnabled: false` isn't
    // silently overridden on a device that has never touched the switch.
    final savedEnabled = await DebugLensSharedPrefs.getString(
      DebugConstants.testerEnabledPrefsKey,
    );
    if (savedEnabled != null) {
      _testerEnabled = savedEnabled == DebugConstants.trueValue;
    }
    final raw = await DebugLensSharedPrefs.getString(
      DebugConstants.testerRoutesPrefsKey,
    );
    if (raw != null && raw.isNotEmpty) {
      try {
        // An empty saved set is honoured: a developer may deliberately have
        // granted a tester nothing at all.
        _testerRoutes = Set<String>.from(jsonDecode(raw) as List);
      } catch (_) {
        // Unreadable — keep the default grants.
      }
    }
    notifyListeners();
  }

  /// Switches between tester and developer and persists the new value.
  Future<void> toggle() async {
    if (!canToggle) return;
    _role = isDeveloper ? DebugRole.tester : DebugRole.developer;
    notifyListeners();
    await DebugLensSharedPrefs.setString(
      DebugConstants.rolePrefsKey,
      _role.name,
    );
  }

  /// Enables or disables the tester role.
  Future<void> setTesterEnabled(bool enabled) async {
    if (_testerEnabled == enabled) return;
    _testerEnabled = enabled;
    if (!enabled && !isDeveloper) {
      _role = DebugRole.developer;
      await DebugLensSharedPrefs.setString(
        DebugConstants.rolePrefsKey,
        _role.name,
      );
    }
    notifyListeners();
    await DebugLensSharedPrefs.setString(
      DebugConstants.testerEnabledPrefsKey,
      enabled ? DebugConstants.trueValue : DebugConstants.falseValue,
    );
  }

  /// Replaces the routes a tester may open, and persists them.
  Future<void> setTesterRoutes(Set<String> routes) async {
    _testerRoutes = {...routes};
    notifyListeners();
    await DebugLensSharedPrefs.setString(
      DebugConstants.testerRoutesPrefsKey,
      jsonEncode(_testerRoutes.toList()),
    );
  }
}
