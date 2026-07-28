import 'package:flutter/material.dart';

import '../shared/debug_strings.dart';
import '../shell/debug_routes.dart';

/// A panel screen that can be opened up to testers.
///
/// Used for `DebugLens.initialTesterAccess` and by the Tester access sheet.
/// Settings is deliberately absent: it is where access is granted, so offering
/// it would let a tester widen their own. Everything else on the dashboard is
/// fair game.
enum DebugScreen {
  network(DebugStrings.dashboardNetwork, Icons.language, DebugRoutes.network),
  logs(DebugStrings.dashboardLogs, Icons.notes, DebugRoutes.logs),
  notifications(
    DebugStrings.dashboardNotifications,
    Icons.notifications_outlined,
    DebugRoutes.notifications,
  ),
  navigation(
    DebugStrings.dashboardNavigation,
    Icons.alt_route,
    DebugRoutes.navigation,
  ),
  bloc(DebugStrings.dashboardBloc, Icons.stream, DebugRoutes.bloc),
  storage(DebugStrings.dashboardStorage, Icons.storage, DebugRoutes.storage),
  device(DebugStrings.dashboardDevice, Icons.phone_iphone, DebugRoutes.device),
  services(
    DebugStrings.dashboardServices,
    Icons.cloud_outlined,
    DebugRoutes.services,
  ),
  locale(DebugStrings.dashboardLocale, Icons.translate, DebugRoutes.locale);

  const DebugScreen(this.label, this.icon, this.route);

  /// Shown beside the switch in the Tester access sheet.
  final String label;

  final IconData icon;

  /// The panel route this screen is reached by — what the grant is keyed on.
  final String route;
}
