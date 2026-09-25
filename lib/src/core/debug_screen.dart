import 'package:flutter/material.dart';

import '../shared/debug_strings.dart';
import '../shell/debug_routes.dart';

/// A panel screen that can be opened up to testers.
enum DebugScreen {
  /// Captured HTTP calls, with their headers, bodies, timings and status.
  network(DebugStrings.dashboardNetwork, Icons.language, DebugRoutes.network),

  /// The log feed, and the switches that decide what is captured into it.
  logs(DebugStrings.dashboardLogs, Icons.notes, DebugRoutes.logs),

  /// Push and local notifications, plus captured deep links.
  notifications(
    DebugStrings.dashboardNotifications,
    Icons.notifications_outlined,
    DebugRoutes.notifications,
  ),

  /// Route events and the live navigator stacks.
  navigation(
    DebugStrings.dashboardNavigation,
    Icons.alt_route,
    DebugRoutes.navigation,
  ),

  /// Bloc and cubit lifecycle events.
  bloc(DebugStrings.dashboardBloc, Icons.stream, DebugRoutes.bloc),

  /// SharedPreferences entries and registered database tables.
  storage(DebugStrings.dashboardStorage, Icons.storage, DebugRoutes.storage),

  /// Device and app facts, and live screen metrics.
  device(DebugStrings.dashboardDevice, Icons.phone_iphone, DebugRoutes.device),

  /// Registered services: remote config, crashes, analytics, traces.
  services(
    DebugStrings.dashboardServices,
    Icons.cloud_outlined,
    DebugRoutes.services,
  ),

  /// The app's active locale strings.
  locale(DebugStrings.dashboardLocale, Icons.translate, DebugRoutes.locale);

  const DebugScreen(this.label, this.icon, this.route);

  /// Shown beside the switch in the Tester access sheet.
  final String label;

  /// Shown on this screen's dashboard tile and in the Tester access sheet.
  final IconData icon;

  /// The panel route this screen is reached by — what the grant is keyed on.
  final String route;
}
