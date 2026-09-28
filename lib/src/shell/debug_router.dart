import 'package:flutter/material.dart';

import '../../debug_lens.dart';
import '../features/network/domain/network_entry.dart';
import '../features/bloc/presentation/views/bloc_screen.dart';
import '../features/storage/presentation/views/database_tables_screen.dart';
import '../features/device/presentation/views/device_info_screen.dart';
import '../features/services/presentation/views/analytics_screen.dart';
import '../features/services/presentation/views/services_screen.dart';
import '../features/services/presentation/views/service_detail_screen.dart';
import '../features/locale/presentation/views/locale_screen.dart';
import '../features/logs/presentation/views/log_detail_screen.dart';
import '../features/logs/presentation/views/logs_screen.dart';
import '../features/navigation/presentation/views/navigation_screen.dart';
import '../features/network/presentation/views/network_detail_screen.dart';
import '../features/network/presentation/views/network_history_screen.dart';
import '../features/network/presentation/views/network_list_screen.dart';
import '../features/notifications/presentation/views/notifications_screen.dart';
import '../features/health/domain/health_report.dart';
import '../features/health/presentation/views/health_report_screen.dart';
import '../features/settings/presentation/views/settings_screen.dart';
import '../features/storage/presentation/views/storage_screen.dart';
import '../features/storage/presentation/views/table_data_screen.dart';
import '../shared/theme/debug_accents.dart';
import '../shared/theme/debug_theme.dart';
import '../shared/widgets/glass_background.dart';
import 'debug_routes.dart';
import 'no_access_screen.dart';

/// Maps DebugLens route names to screens for the panel's nested [Navigator].
class DebugRouter {
  DebugRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => _RoutePage(settings: settings),
      settings: settings,
    );
  }

  /// A tab's root screen, swapped in without a transition.
  static Route<void> tabRoute(String name) {
    final settings = RouteSettings(name: name);
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => _RoutePage(settings: settings),
    );
  }
}

/// [settings]'s screen, themed with its route's accent.
class _RoutePage extends StatelessWidget {
  final RouteSettings settings;

  const _RoutePage({required this.settings});

  @override
  Widget build(BuildContext context) {
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
      case DebugRoutes.services:
        page = const ServicesScreen();
      case DebugRoutes.analytics:
        page = const AnalyticsScreen();
      case DebugRoutes.serviceDetail:
        page = ServiceDetailScreen(service: args as DebugLensService);
      case DebugRoutes.locale:
        page = const LocaleScreen();
      case DebugRoutes.settings:
        page = const SettingsScreen();
      case DebugRoutes.healthReport:
        page = HealthReportScreen(report: args as HealthReport);
      case DebugRoutes.noAccess:
      default:
        page = const NoAccessScreen();
    }
    final accent = DebugAccents.forRoute(settings.name);
    return Theme(
      data: DebugTheme.build(accent),
      // Opaque, so a page mid-transition covers the one beneath it.
      child: Stack(
        fit: StackFit.expand,
        children: [const GlassBackground(), page],
      ),
    );
  }
}
