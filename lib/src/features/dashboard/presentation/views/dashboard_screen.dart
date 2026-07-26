import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shell/debug_lens_controller.dart';
import '../../../../core/debug_role.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/matrix_rain.dart';
import '../../data/dash_order_store.dart';
import '../../domain/dash_item.dart';
import '../widgets/developer_password_dialog.dart';
import '../widgets/reorderable_dash_grid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// Declared order — the fallback, and the set the saved order is applied to.
  static const _items = <DashItem>[
    DashItem(
      Icons.language,
      DebugStrings.dashboardNetwork,
      DebugRoutes.network,
    ),
    DashItem(Icons.notes, DebugStrings.dashboardLogs, DebugRoutes.logs),
    DashItem(
      Icons.notifications_outlined,
      DebugStrings.dashboardNotifications,
      DebugRoutes.notifications,
    ),
    DashItem(
      Icons.alt_route,
      DebugStrings.dashboardNavigation,
      DebugRoutes.navigation,
    ),
    DashItem(Icons.stream, DebugStrings.dashboardBloc, DebugRoutes.bloc),
    DashItem(Icons.storage, DebugStrings.dashboardStorage, DebugRoutes.storage),
    DashItem(
      Icons.phone_iphone,
      DebugStrings.dashboardDevice,
      DebugRoutes.device,
    ),
    DashItem(
      Icons.cloud_outlined,
      DebugStrings.dashboardServices,
      DebugRoutes.services,
    ),
    DashItem(Icons.translate, DebugStrings.dashboardLocale, DebugRoutes.locale),
    DashItem(
      Icons.settings,
      DebugStrings.dashboardSettings,
      DebugRoutes.settings,
    ),
  ];

  /// The declared order until the saved one loads — a frame or two, and
  /// identical when nothing has been rearranged yet.
  List<DashItem> _ordered = _items;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final ordered = await DashOrderStore.ordered(_items);
    if (!mounted) return;
    setState(() => _ordered = ordered);
  }

  /// Applied immediately and persisted in the background — the write is a
  /// preference, not something the grid should wait on.
  ///
  /// [visible] is what the grid was showing, which for a tester is a filtered
  /// subset. The reordered tiles are spliced back into the slots they already
  /// occupied, so tiles the current role can't see keep their positions and
  /// rearranging in one role never rewrites the other's order.
  void _onReorder(List<DashItem> visible) {
    final routes = {for (final item in visible) item.route};
    final slots = <int>[
      for (var i = 0; i < _ordered.length; i++)
        if (routes.contains(_ordered[i].route)) i,
    ];
    final next = [..._ordered];
    for (var i = 0; i < slots.length; i++) {
      next[slots[i]] = visible[i];
    }
    setState(() => _ordered = next);
    DashOrderStore.save(next);
  }

  Future<void> _toggleRole(BuildContext context) async {
    final roleController = context.read<DebugRoleController>();
    // Switching INTO developer requires the password; leaving it is free.
    if (!roleController.isDeveloper) {
      final unlocked = await showDialog<bool>(
        context: context,
        builder: (_) => const DeveloperPasswordDialog(),
      );
      if (unlocked != true) return;
    }
    if (!context.mounted) return;

    // Curtain first: the rain covers the screen, the role flips behind it, and
    // the rain fades out onto the new dashboard. Toggling first would show the
    // rearranged grid and only then play the animation announcing it.
    final becomingDeveloper = !roleController.isDeveloper;
    MatrixRain.show(
      context,
      label: becomingDeveloper
          ? DebugStrings.roleDeveloper
          : DebugStrings.roleTester,
    );
    await Future<void>.delayed(MatrixRain.coverDelay);

    // Deliberately unguarded by `mounted`: the switch was asked for, and
    // `toggle` only touches the controller, so closing the panel mid-animation
    // shouldn't silently drop it.
    await roleController.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final isDeveloper = context.watch<DebugRoleController>().isDeveloper;
    // Testers can only open Network; developers see everything.
    final items = isDeveloper
        ? _ordered
        : _ordered.where((i) => i.route == DebugRoutes.network).toList();

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          // Long-press the title to switch role (tester ↔ developer).
          onLongPress: () => _toggleRole(context),
          child: const Text(DebugStrings.dashboardTitle),
        ),
        actions: [
          IconButton(
            tooltip: DebugStrings.commonClose,
            icon: const Icon(Icons.close),
            onPressed: () => context.read<DebugLensController>().close(),
          ),
        ],
      ),
      // Long-press a tile to drag it somewhere else; the order is remembered.
      body: ReorderableDashGrid(items: items, onReorder: _onReorder),
    );
  }
}
