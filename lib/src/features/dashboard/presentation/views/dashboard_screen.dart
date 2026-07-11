import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shell/debug_lens_controller.dart';
import '../../../../core/debug_role.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/matrix_rain.dart';
import 'dash_card.dart';
import 'dash_item.dart';
import 'developer_password_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
      Icons.local_fire_department,
      DebugStrings.dashboardFirebase,
      DebugRoutes.firebase,
    ),
    DashItem(Icons.translate, DebugStrings.dashboardLocale, DebugRoutes.locale),
    DashItem(
      Icons.settings,
      DebugStrings.dashboardSettings,
      DebugRoutes.settings,
    ),
  ];

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
    await roleController.toggle();
    if (!context.mounted) return;
    // Matrix-style "transformation" flourish announcing the new role.
    MatrixRain.show(
      context,
      label: roleController.isDeveloper
          ? DebugStrings.roleDeveloper
          : DebugStrings.roleTester,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDeveloper = context.watch<DebugRoleController>().isDeveloper;
    // Testers can only open Network; developers see everything.
    final items = isDeveloper
        ? _items
        : _items.where((i) => i.route == DebugRoutes.network).toList();

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
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [for (final item in items) DashCard(item: item)],
      ),
    );
  }
}
