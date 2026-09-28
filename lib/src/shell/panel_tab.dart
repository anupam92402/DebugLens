import 'package:flutter/material.dart';

import '../core/debug_role.dart';
import '../shared/debug_constants.dart';
import '../shared/debug_strings.dart';
import '../shared/theme/debug_accents.dart';
import 'debug_routes.dart';

/// One panel screen reachable from the bottom bar: icon, title and root route.
class PanelTab {
  final IconData icon;
  final String title;
  final String route;

  const PanelTab(this.icon, this.title, this.route);

  Color get color => DebugAccents.forRoute(route);

  /// Every tab, in default order — also the order of the More sheet.
  static const all = <PanelTab>[
    PanelTab(
      Icons.language,
      DebugStrings.dashboardNetwork,
      DebugRoutes.network,
    ),
    PanelTab(Icons.notes, DebugStrings.dashboardLogs, DebugRoutes.logs),
    PanelTab(
      Icons.insights,
      DebugStrings.dashboardAnalytics,
      DebugRoutes.analytics,
    ),
    PanelTab(
      Icons.alt_route,
      DebugStrings.dashboardNavigation,
      DebugRoutes.navigation,
    ),
    PanelTab(
      Icons.notifications_outlined,
      DebugStrings.dashboardNotifications,
      DebugRoutes.notifications,
    ),
    PanelTab(Icons.stream, DebugStrings.dashboardBloc, DebugRoutes.bloc),
    PanelTab(Icons.storage, DebugStrings.dashboardStorage, DebugRoutes.storage),
    PanelTab(
      Icons.phone_iphone,
      DebugStrings.dashboardDevice,
      DebugRoutes.device,
    ),
    PanelTab(
      Icons.cloud_outlined,
      DebugStrings.dashboardServices,
      DebugRoutes.services,
    ),
    PanelTab(Icons.translate, DebugStrings.dashboardLocale, DebugRoutes.locale),
    PanelTab(
      Icons.settings,
      DebugStrings.dashboardSettings,
      DebugRoutes.settings,
    ),
  ];

  /// Tabs [role] may open.
  static List<PanelTab> visibleTo(DebugRoleController role) =>
      all.where((t) => role.canOpen(t.route)).toList();
}

/// [tabs] split into the bar and the More sheet: Network pinned first, then
/// [slots] in order, topped up in default order when a slot's tab is hidden
/// from the role. One more tab than the bar holds takes More's slot instead of
/// hiding behind it.
class PanelTabSplit {
  final List<PanelTab> bar;
  final List<PanelTab> more;

  const PanelTabSplit._(this.bar, this.more);

  factory PanelTabSplit(List<PanelTab> tabs, List<String> slots) {
    if (tabs.length <= DebugConstants.panelBarTabs + 1) {
      return PanelTabSplit._(tabs, const []);
    }
    final byRoute = {for (final t in tabs) t.route: t};
    final bar = <PanelTab>[
      ?byRoute[DebugRoutes.network],
      for (final route in slots)
        if (byRoute[route] case final tab? when route != DebugRoutes.network)
          tab,
    ];
    for (final tab in tabs) {
      if (bar.length >= DebugConstants.panelBarTabs) break;
      if (!bar.contains(tab)) bar.add(tab);
    }
    final shown = bar.take(DebugConstants.panelBarTabs).toList();
    return PanelTabSplit._(
      shown,
      tabs.where((t) => !shown.contains(t)).toList(),
    );
  }
}
