/// Named routes for the DebugLens nested navigator, plus [panelRouteName] for
/// the panel route on the host navigator. Every name is prefixed with
/// `debug_lens/` so DebugLens's routes are namespaced and never collide with
/// the host app's own routes.
class DebugRoutes {
  DebugRoutes._();

  /// Common prefix on every DebugLens route — used to tell DebugLens's own
  /// navigation apart from the host app's (e.g. to filter it out).
  static const String prefix = 'debug_lens/';

  /// Name of DebugLens's panel route on the *host* navigator, so it shows a
  /// readable label (instead of `PageRouteBuilder`) on the Navigation screen.
  static const String panelRouteName = 'debug_lens/panel';

  static const dashboard = 'debug_lens/dashboard';
  static const network = 'debug_lens/network';
  static const networkDetail = 'debug_lens/network/detail';
  static const networkHistory = 'debug_lens/network/history';
  static const logs = 'debug_lens/logs';
  static const logDetail = 'debug_lens/logs/detail';
  static const notifications = 'debug_lens/notifications';
  static const navigation = 'debug_lens/navigation';
  static const bloc = 'debug_lens/bloc';
  static const storage = 'debug_lens/storage';
  static const databaseTables = 'debug_lens/storage/database';
  static const databaseData = 'debug_lens/storage/database/table';
  static const device = 'debug_lens/device';
  static const firebase = 'debug_lens/firebase';
  static const firebaseService = 'debug_lens/firebase/service';
  static const locale = 'debug_lens/locale';
  static const settings = 'debug_lens/settings';
}
