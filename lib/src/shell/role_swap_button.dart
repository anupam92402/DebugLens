import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/debug_role.dart';
import '../shared/debug_strings.dart';
import '../shared/theme/debug_colors.dart';
import '../shared/widgets/debug_widgets.dart';
import '../shared/widgets/matrix_rain.dart';

/// DEV / QA tag beside a screen title showing the current role, with a tap to
/// swap it.
class RoleSwapButton extends StatelessWidget {
  const RoleSwapButton({super.key});

  Future<void> _swap(BuildContext context) async {
    final role = context.read<DebugRoleController>();
    if (!role.canToggle) return;

    MatrixRain.show(
      context,
      label: role.isDeveloper
          ? DebugStrings.roleTester
          : DebugStrings.roleDeveloper,
    );
    await Future<void>.delayed(MatrixRain.coverDelay);
    await role.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<DebugRoleController>();
    if (!role.canToggle) return const SizedBox.shrink();

    final tone = role.isDeveloper ? DebugColors.success : DebugColors.warning;
    return Tooltip(
      message: DebugStrings.dashboardRoleSwap(
        role.isDeveloper ? DebugStrings.roleDeveloper : DebugStrings.roleTester,
      ),
      child: InkWell(
        onTap: () => _swap(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.14),
            border: Border.all(color: tone.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                role.isDeveloper
                    ? DebugStrings.roleDeveloperShort
                    : DebugStrings.roleTesterShort,
                style: monoStyle(size: 10, color: tone),
              ),
              const SizedBox(width: 4),
              Icon(Icons.sync, size: 12, color: tone),
            ],
          ),
        ),
      ),
    );
  }
}
