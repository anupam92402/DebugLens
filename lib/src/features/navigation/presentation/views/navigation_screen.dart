import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../widgets/nav_events_tab.dart';
import '../widgets/nav_stack_tab.dart';

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
          title: const Text(DebugStrings.navigationTitle),
          actions: [
            IconButton(
              tooltip: DebugStrings.navigationClearTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                context.read<DebugStore>().clearNavigation();
                DebugToast.show(context, DebugStrings.navigationClearedToast);
              },
            ),
          ],
          bottom: TabBar(
            labelColor: accent,
            indicatorColor: accent,
            unselectedLabelColor: DebugPalette.textMuted,
            tabs: const [
              Tab(text: DebugStrings.navigationTabEvents),
              Tab(text: DebugStrings.navigationTabStack),
            ],
          ),
        ),
        body: const TabBarView(children: [NavEventsTab(), NavStackTab()]),
      ),
    );
  }
}
