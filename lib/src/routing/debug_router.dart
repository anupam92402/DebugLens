import 'package:flutter/material.dart';

import '../../debug_lens.dart';
import '../core/debug_lens_logger.dart';
import '../core/models/network_entry.dart';
import '../ui/screens/bloc_screen.dart';
import '../ui/screens/dashboard_screen.dart';
import '../ui/screens/database_tables_screen.dart';
import '../ui/screens/device_info_screen.dart';
import '../ui/screens/firebase_screen.dart';
import '../ui/screens/firebase_service_screen.dart';
import '../ui/screens/locale_screen.dart';
import '../ui/screens/log_detail_screen.dart';
import '../ui/screens/logs_screen.dart';
import '../ui/screens/navigation_screen.dart';
import '../ui/screens/network_detail_screen.dart';
import '../ui/screens/network_history_screen.dart';
import '../ui/screens/network_list_screen.dart';
import '../ui/screens/notifications_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/storage_screen.dart';
import '../ui/screens/table_data_screen.dart';
import '../ui/theme/debug_accents.dart';
import '../ui/theme/debug_theme.dart';
import 'debug_routes.dart';

/// Maps DebugLens route names to screens for the panel's nested [Navigator].
class DebugRouter {
  DebugRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget page;
    switch (settings.name) {
      case DebugRoutes.network:
        page = const NetworkListScreen();
      case DebugRoutes.networkDetail:
        page = NetworkDetailScreen(entry: args as NetworkEntry);
      case DebugRoutes.networkHistory:
        page = const NetworkHistoryScreen();
      case DebugRoutes.logs:
        page = const LogsScreen();
      case DebugRoutes.logDetail:
        page = LogDetailScreen(record: args as DebugLogRecord);
      case DebugRoutes.notifications:
        page = const NotificationsScreen();
      case DebugRoutes.navigation:
        page = const NavigationScreen();
      case DebugRoutes.bloc:
        page = const BlocScreen();
      case DebugRoutes.storage:
        page = const StorageScreen();
      case DebugRoutes.databaseTables:
        page = DatabaseTablesScreen(database: args as DebugLensDatabase);
      case DebugRoutes.databaseData:
        final dbArgs = args as DatabaseTableArgs;
        page = TableDataScreen(
          database: dbArgs.database,
          table: dbArgs.table,
        );
      case DebugRoutes.device:
        page = const DeviceInfoScreen();
      case DebugRoutes.firebase:
        page = const FirebaseScreen();
      case DebugRoutes.firebaseService:
        page = FirebaseServiceScreen(
          service: args as DebugLensFirebaseService,
        );
      case DebugRoutes.locale:
        page = const LocaleScreen();
      case DebugRoutes.settings:
        page = const SettingsScreen();
      case DebugRoutes.dashboard:
      default:
        page = const DashboardScreen();
    }
    final accent = DebugAccents.forRoute(settings.name);
    return MaterialPageRoute<void>(
      builder: (_) => Theme(data: DebugTheme.build(accent), child: page),
      settings: settings,
    );
  }
}
