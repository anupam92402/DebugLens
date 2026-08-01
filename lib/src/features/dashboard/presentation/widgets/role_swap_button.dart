import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_role.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Small chip beside the dashboard title showing the current role, with a tap
/// to swap it.
class RoleSwapButton extends StatelessWidget {
  final VoidCallback onSwap;

  const RoleSwapButton({super.key, required this.onSwap});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<DebugRoleController>();
    if (!role.canToggle) return const SizedBox.shrink();

    final label = role.isDeveloper
        ? DebugStrings.roleDeveloper
        : DebugStrings.roleTester;
    return Tooltip(
      message: DebugStrings.dashboardRoleSwap(label),
      child: InkWell(
        onTap: onSwap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: monoStyle(size: 10, color: DebugColors.textMuted),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.sync, size: 14, color: DebugColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
