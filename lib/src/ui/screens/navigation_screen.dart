import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/debug_store.dart';
import '../theme/debug_theme.dart';
import '../widgets/debug_toast.dart';
import '../widgets/navigation/nav_events_tab.dart';
import '../widgets/navigation/nav_stack_tab.dart';

/// Two-tab view of the navigator observer's captures. Owns the AppBar
/// (title, clear action, tab bar). Both tab bodies are extracted widgets
/// in `widgets/navigation/`.
class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Navigation'),
          actions: [
            IconButton(
              tooltip: 'Clear navigation logs',
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                context.read<DebugStore>().clearNavigation();
                DebugToast.show(context, 'Navigation logs cleared');
              },
            ),
          ],
          bottom: TabBar(
            labelColor: accent,
            indicatorColor: accent,
            unselectedLabelColor: DebugPalette.textMuted,
            tabs: const [Tab(text: 'Events'), Tab(text: 'Stack')],
          ),
        ),
        body: const TabBarView(
          children: [
            NavEventsTab(),
            NavStackTab(),
          ],
        ),
      ),
    );
  }
}
