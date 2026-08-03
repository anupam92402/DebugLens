import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shell/debug_lens_controller.dart';
import '../../../../core/debug_role.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/matrix_rain.dart';
import '../../domain/dash_item.dart';
import '../widgets/dash_grid.dart';
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
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(DebugStrings.dashboardTitle),
            const SizedBox(width: 8),
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
      body: Builder(
        builder: (context) {
          // Developers see everything; testers see only what they've been
          // granted (configured from Settings → Tester access).
          final items = role.isDeveloper
              ? _items
              : _items.where((i) => role.canOpen(i.route)).toList();
          // The tour measures the first tile, whichever it is after role
          // filtering.
          final firstRoute = items.isEmpty ? null : items.first.route;
          return DashGrid(
            items: items,
            cardKey: (route) => route == firstRoute ? _firstTileKey : null,
          );
        },
      ),
    );
  }
}
