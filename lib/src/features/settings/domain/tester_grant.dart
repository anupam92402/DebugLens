import 'package:flutter/material.dart';

import '../../../shared/debug_strings.dart';
import '../../../shell/debug_routes.dart';

/// A screen a developer can open up to testers.
///
/// Settings is deliberately absent: it is where access is granted, so offering
/// it would let a tester widen their own. Everything else on the dashboard is
/// fair game.
enum TesterGrant {
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

  const TesterGrant(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}
