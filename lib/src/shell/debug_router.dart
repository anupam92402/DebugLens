import 'package:flutter/material.dart';

import '../../debug_lens.dart';
import '../features/network/domain/network_entry.dart';
import '../features/bloc/presentation/views/bloc_screen.dart';
import '../features/dashboard/presentation/views/dashboard_screen.dart';
import '../features/storage/presentation/views/database_tables_screen.dart';
import '../features/device/presentation/views/device_info_screen.dart';
import '../features/firebase/presentation/views/firebase_screen.dart';
import '../features/firebase/presentation/views/firebase_service_screen.dart';
import '../features/locale/presentation/views/locale_screen.dart';
import '../features/logs/presentation/views/log_detail_screen.dart';
import '../features/logs/presentation/views/logs_screen.dart';
import '../features/navigation/presentation/views/navigation_screen.dart';
import '../features/network/presentation/views/network_detail_screen.dart';
import '../features/network/presentation/views/network_history_screen.dart';
import '../features/network/presentation/views/network_list_screen.dart';
import '../features/notifications/presentation/views/notifications_screen.dart';
import '../features/settings/presentation/views/settings_screen.dart';
import '../features/storage/presentation/views/storage_screen.dart';
import '../features/storage/presentation/views/table_data_screen.dart';
import '../shared/theme/debug_accents.dart';
import '../shared/theme/debug_theme.dart';
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
        page = TableDataScreen(database: dbArgs.database, table: dbArgs.table);
      case DebugRoutes.device:
        page = const DeviceInfoScreen();
      case DebugRoutes.firebase:
        page = const FirebaseScreen();
      case DebugRoutes.firebaseService:
        page = FirebaseServiceScreen(service: args as DebugLensFirebaseService);
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
