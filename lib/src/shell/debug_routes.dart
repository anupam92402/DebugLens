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

  static const noAccess = 'debug_lens/no_access';

  // DebugLens's own bottom sheets and dialogs, pushed on the host navigator.
  static const moreServicesSheet = 'debug_lens/sheet_more_services';
  static const roleSheet = 'debug_lens/sheet_role';
  static const testerAccessSheet = 'debug_lens/sheet_tester_access';
  static const bubbleSheet = 'debug_lens/sheet_bubble';
  static const limitsSheet = 'debug_lens/sheet_limits';
  static const healthReportsSheet = 'debug_lens/sheet_health_reports';
  static const apiCallsSheet = 'debug_lens/sheet_api_calls';
  static const logCaptureSheet = 'debug_lens/sheet_log_capture';
  static const appVersionDialog = 'debug_lens/dialog_app_version';
  static const errorScreenDialog = 'debug_lens/dialog_error_screen';
  static const clearDataDialog = 'debug_lens/dialog_clear_data';
  static const limitEditDialog = 'debug_lens/dialog_limit_edit';
  static const prefDetailDialog = 'debug_lens/dialog_pref_detail';
  static const configValueDialog = 'debug_lens/dialog_config_value';
  static const configEditDialog = 'debug_lens/dialog_config_edit';
  static const serviceRestartDialog = 'debug_lens/dialog_service_restart';
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
  static const services = 'debug_lens/services';
  static const analytics = 'debug_lens/analytics';
  static const serviceDetail = 'debug_lens/services/detail';
  static const locale = 'debug_lens/locale';
  static const settings = 'debug_lens/settings';
  static const healthReport = 'debug_lens/settings/health';
}
