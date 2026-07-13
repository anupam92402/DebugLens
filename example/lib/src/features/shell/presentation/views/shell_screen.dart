import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/firebase/mock_firebase.dart';
import '../../../../core/navigation/tab_routes.dart';
import '../../../home/presentation/widgets/add_activity_sheet.dart';
import '../cubit/shell_cubit.dart';
import '../widgets/shell_bottom_bar.dart';
import '../widgets/tab_navigator.dart';

/// App shell: bottom bar with 2 tabs + centre-docked FAB (3 options total).
///
/// Each tab hosts its own nested [Navigator] (see [TabNavigator]) observed by
/// DebugLens with a per-tab label, so in-tab pushes keep the bottom bar
/// visible and show up grouped on the Navigation screen. Each tab draws its
/// own AppBar.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  final _homeNavigatorKey = GlobalKey<NavigatorState>();
  final _playgroundNavigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? _tabNavigator(int index) =>
      (index == 0 ? _homeNavigatorKey : _playgroundNavigatorKey).currentState;

  void _onTabSelected(int index) {
    final cubit = context.read<ShellCubit>();
    if (cubit.state == index) {
      // Re-tapping the active tab pops its nested stack back to the root.
      _tabNavigator(index)?.popUntil((route) => route.isFirst);
    } else {
      cubit.select(index);
      // Mock Firebase: log the screen view + a crash breadcrumb for the tab.
      final tab = index == 0 ? 'home' : 'apis';
      MockFirebase.analytics.logScreenView(tab);
      MockFirebase.crashlytics
        ..log('Navigated to $tab tab')
        ..setCustomKey('current_tab', tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = context.watch<ShellCubit>().state;
    return PopScope(
      // System back pops the active tab's nested stack first; only exits the
      // app once that stack is at its root.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final navigator = _tabNavigator(index);
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: index,
          children: [
            TabNavigator(
              navigatorKey: _homeNavigatorKey,
              label: 'home-tab',
              initialRoute: TabRoutes.homeRoot,
              onGenerateRoute: TabRoutes.onGenerateRoute,
            ),
            TabNavigator(
              navigatorKey: _playgroundNavigatorKey,
              label: 'playground-tab',
              initialRoute: TabRoutes.playgroundRoot,
              onGenerateRoute: TabRoutes.onGenerateRoute,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Add activity',
          shape: const CircleBorder(), // M3 default is a rounded square
          onPressed: () => AddActivitySheet.show(context),
          child: const Icon(Icons.add_rounded),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: ShellBottomBar(onSelect: _onTabSelected),
      ),
    );
  }
}
