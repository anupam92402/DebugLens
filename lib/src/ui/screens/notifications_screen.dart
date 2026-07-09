import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/debug_store.dart';
import '../theme/debug_theme.dart';
import '../widgets/notifications/deeplinks_tab.dart';
import '../widgets/notifications/notifications_tab.dart';

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
          title: const Text('Notifications / Deeplinks'),
          bottom: TabBar(
            labelColor: accent,
            indicatorColor: accent,
            unselectedLabelColor: DebugPalette.textMuted,
            tabs: const [Tab(text: 'Notifications'), Tab(text: 'Deeplinks')],
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
