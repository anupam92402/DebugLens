import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_role.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_bottom_sheet.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/glass.dart';
import '../../../../core/debug_screen.dart';

/// Bottom sheet for choosing which screens a tester may open.
///
/// Ticking a screen here changes what the dashboard shows once the role is
/// Tester; it has no effect while the panel is in Developer mode, which sees
/// everything regardless. Settings is not offered — granting it would let a
/// tester widen their own access.
class TesterAccessSheet extends StatelessWidget {
  const TesterAccessSheet({super.key});

  static Future<void> show(BuildContext context) => showDebugBottomSheet<void>(
    context,
    builder: (_) => const TesterAccessSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final role = context.watch<DebugRoleController>();
    final granted = role.testerRoutes;
    return GlassSurface(
      squareBottom: true,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DebugStrings.settingsTesterAccess,
                    style: monoStyle(size: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DebugStrings.settingsTesterAccessHint,
                    style: monoStyle(size: 11, color: DebugColors.textMuted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                children: [
                  for (final grant in DebugScreen.values)
                    SwitchListTile(
                      dense: true,
                      secondary: Icon(grant.icon, size: 20),
                      title: Text(grant.label, style: monoStyle(size: 13)),
                      value: granted.contains(grant.route),
                      onChanged: (on) {
                        final next = {...granted};
                        if (on) {
                          next.add(grant.route);
                        } else {
                          next.remove(grant.route);
                        }
                        role.setTesterRoutes(next);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
