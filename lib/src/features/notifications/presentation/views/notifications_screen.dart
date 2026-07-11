import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../../../shared/debug_strings.dart';
import '../widgets/deeplinks_tab.dart';
import '../widgets/notifications_tab.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Two-tab view of push/local notifications + captured deep-links.
/// Thin assembler — both tab bodies live in `widgets/notifications/`.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final store = context.watch<DebugStore>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(DebugStrings.notificationsTitle),
          bottom: TabBar(
            labelColor: accent,
            indicatorColor: accent,
            unselectedLabelColor: DebugColors.textMuted,
            tabs: const [
              Tab(text: DebugStrings.notificationsTabNotifications),
              Tab(text: DebugStrings.notificationsTabDeeplinks),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            NotificationsTab(items: store.notifications),
            DeeplinksTab(items: store.deeplinks),
          ],
        ),
      ),
    );
  }
}
