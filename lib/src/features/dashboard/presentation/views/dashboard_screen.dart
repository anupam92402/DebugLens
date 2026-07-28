import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shell/debug_lens_controller.dart';
import '../../../../core/debug_role.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/matrix_rain.dart';
import '../../data/dash_order_store.dart';
import '../../domain/dash_item.dart';
import '../widgets/reorderable_dash_grid.dart';
import '../widgets/role_swap_button.dart';
import '../../../walkthrough/data/walkthrough_store.dart';
import '../../../walkthrough/domain/walkthrough_step.dart';
import '../../../walkthrough/presentation/widgets/walkthrough_overlay.dart';

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

  /// Coach-mark targets. Global because the tour measures their render boxes
  /// from outside their own subtrees.
  final GlobalKey _firstTileKey = GlobalKey();
  final GlobalKey _roleKey = GlobalKey();
  final GlobalKey _closeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // After the first frame, so the targets have been laid out and can be
    // measured — before that every rect would be null.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
  }

  /// Shows the first-run tour once, over the panel's overlay so it can dim the
  /// AppBar as well as the grid.
  Future<void> _maybeShowTour() async {
    if (await WalkthroughStore.instance.hasSeen()) return;
    if (!mounted) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    // Marked seen on show, not on finish: someone who closes the panel midway
    // has still seen it, and being walked through twice is worse than missing
    // the last step.
    await WalkthroughStore.instance.markSeen();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => WalkthroughOverlay(
        steps: [
          WalkthroughStep(
            title: DebugStrings.walkthroughPickTitle,
            body: DebugStrings.walkthroughPickBody,
            target: _firstTileKey,
          ),
          WalkthroughStep(
            title: DebugStrings.walkthroughRoleTitle,
            body: DebugStrings.walkthroughRoleBody,
            target: _roleKey,
          ),
          WalkthroughStep(
            title: DebugStrings.walkthroughExploreTitle,
            body: DebugStrings.walkthroughExploreBody,
            target: _closeKey,
          ),
        ],
        onFinish: entry.remove,
      ),
    );
    overlay.insert(entry);
  }

  /// Applied immediately and persisted in the background — the write is a
  /// preference, not something the grid should wait on.
  ///
  /// [visible] is what the grid was showing, which for a tester is a filtered
  /// subset. The reordered tiles are spliced back into the slots they already
  /// occupied, so tiles the current role can't see keep their positions and
  /// rearranging in one role never rewrites the other's order.
  void _onReorder(List<DashItem> visible) {
    final ordered = DashOrderStore.instance.ordered(_items);
    final routes = {for (final item in visible) item.route};
    final slots = <int>[
      for (var i = 0; i < ordered.length; i++)
        if (routes.contains(ordered[i].route)) i,
    ];
    final next = [...ordered];
    for (var i = 0; i < slots.length; i++) {
      next[slots[i]] = visible[i];
    }
    DashOrderStore.instance.save(next);
  }

  Future<void> _toggleRole(BuildContext context) async {
    final roleController = context.read<DebugRoleController>();

    // Belt and braces: `RoleSwapButton` already hides itself when the tester
    // role is switched off, so this shouldn't be reachable — but bail before
    // the rain rather than play a transition that lands where it started.
    if (!roleController.canToggle) return;

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
    final role = context.watch<DebugRoleController>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(DebugStrings.dashboardTitle),
            const SizedBox(width: 8),
            // Hides itself when the tester role is switched off.
            RoleSwapButton(key: _roleKey, onSwap: () => _toggleRole(context)),
          ],
        ),
        actions: [
          IconButton(
            key: _closeKey,
            tooltip: DebugStrings.commonClose,
            icon: const Icon(Icons.close),
            onPressed: () => context.read<DebugLensController>().close(),
          ),
        ],
      ),
      // Long-press a tile to drag it somewhere else; the order is remembered.
      // Listening to the store keeps this in step with a reset from Settings,
      // which happens with this screen still mounted underneath.
      body: ListenableBuilder(
        listenable: DashOrderStore.instance,
        builder: (context, _) {
          final ordered = DashOrderStore.instance.ordered(_items);
          // Developers see everything; testers see only what they've been
          // granted (configured from Settings → Tester access).
          final items = role.isDeveloper
              ? ordered
              : ordered.where((i) => role.canOpen(i.route)).toList();
          // The tour measures the first tile, whichever it happens to be after
          // reordering and role filtering.
          final firstRoute = items.isEmpty ? null : items.first.route;
          return ReorderableDashGrid(
            items: items,
            onReorder: _onReorder,
            cardKey: (route) => route == firstRoute ? _firstTileKey : null,
          );
        },
      ),
    );
  }
}
