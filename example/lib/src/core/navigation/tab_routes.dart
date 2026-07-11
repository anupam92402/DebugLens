import 'package:flutter/material.dart';

import '../../features/home/presentation/views/activity_detail_screen.dart';
import '../../features/home/presentation/views/home_tab.dart';
import '../../features/insights/domain/weekly_stat.dart';
import '../../features/insights/presentation/views/insights_tab.dart';
import '../../features/insights/presentation/views/stat_detail_screen.dart';

/// Single route factory shared by every tab's nested navigator. Route names
/// are namespaced per tab (`home/...`, `insights/...`), so one switch serves
/// them all — DebugLens records whatever name/arguments the settings carry.
class TabRoutes {
  TabRoutes._();

  static const String homeRoot = 'home';
  static const String activityDetail = 'home/activity-detail';
  static const String insightsRoot = 'insights';
  static const String statDetail = 'insights/stat-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = switch (settings.name) {
      activityDetail => (_) => const ActivityDetailScreen(),
      insightsRoot => (_) => const InsightsTab(),
      // The tapped WeeklyStat travels as route arguments.
      statDetail => (_) => StatDetailScreen(
        stat: settings.arguments! as WeeklyStat,
      ),
      // homeRoot — and, defensively, any unknown name.
      _ => (BuildContext _) => const HomeTab(),
    };
    return MaterialPageRoute<void>(settings: settings, builder: builder);
  }
}
