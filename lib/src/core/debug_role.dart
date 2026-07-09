import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Access role for the DebugLens panel.
///
/// - [tester] (default): can only open the Network screen.
/// - [developer]: can open every screen.
enum DebugRole { tester, developer }

/// Holds the current [DebugRole], persisted with `shared_preferences` so the
/// choice survives across app launches and is only reset when the user clears
/// app data or reinstalls. Default is [DebugRole.tester].
class DebugRoleController extends ChangeNotifier {
  static const String _prefsKey = 'debug_lens_role';

  DebugRole _role = DebugRole.tester;

  DebugRole get role => _role;
  bool get isDeveloper => _role == DebugRole.developer;

  DebugRoleController() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_prefsKey) == DebugRole.developer.name) {
        _role = DebugRole.developer;
        notifyListeners();
      }
    } catch (_) {
      // Storage unavailable — keep the default tester role.
    }
  }

  /// Switches between tester and developer and persists the new value.
  Future<void> toggle() async {
    _role = isDeveloper ? DebugRole.tester : DebugRole.developer;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _role.name);
    } catch (_) {
      // Persistence failed — the in-memory role still applies this session.
    }
  }
}
