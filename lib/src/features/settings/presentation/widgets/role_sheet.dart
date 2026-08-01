import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_role.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_bottom_sheet.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/glass.dart';

/// Bottom sheet showing the panel's two access roles.
class RoleSheet extends StatelessWidget {
  const RoleSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showDebugBottomSheet<void>(context, builder: (_) => const RoleSheet());

  @override
  Widget build(BuildContext context) {
    final role = context.watch<DebugRoleController>();
    return GlassSurface(
      squareBottom: true,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                DebugStrings.settingsModeTitle,
                style: monoStyle(size: 14),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.code, size: 20),
              title: Text(
                DebugStrings.roleDeveloper,
                style: monoStyle(size: 13),
              ),
              subtitle: Text(
                DebugStrings.settingsModeDeveloperHint,
                style: monoStyle(size: 11, color: DebugColors.textMuted),
              ),
              trailing: role.isDeveloper
                  ? const Icon(
                      Icons.check,
                      size: 18,
                      color: DebugColors.success,
                    )
                  : null,
            ),
            const Divider(height: 1, color: DebugColors.border),
            SwitchListTile(
              secondary: const Icon(Icons.visibility_outlined, size: 20),
              title: Text(DebugStrings.roleTester, style: monoStyle(size: 13)),
              subtitle: Text(
                DebugStrings.settingsModeTesterHint,
                style: monoStyle(size: 11, color: DebugColors.textMuted),
              ),
              value: role.testerEnabled,
              onChanged: role.setTesterEnabled,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
