import 'package:flutter/material.dart';

import '../shared/debug_strings.dart';
import '../shared/theme/debug_colors.dart';
import '../shared/widgets/debug_bottom_sheet.dart';
import '../shared/widgets/debug_widgets.dart';
import '../shared/widgets/debug_sheet_surface.dart';
import 'panel_tab.dart';
import '../shell/debug_routes.dart';

/// Bottom sheet listing the tabs that don't fit the bar. Pops with the picked
/// tab's route.
class PanelMoreSheet extends StatelessWidget {
  final List<PanelTab> tabs;
  final String current;

  const PanelMoreSheet({super.key, required this.tabs, required this.current});

  static Future<String?> show(
    BuildContext context, {
    required List<PanelTab> tabs,
    required String current,
  }) => showDebugBottomSheet<String>(
    context,
    name: DebugRoutes.moreServicesSheet,
    builder: (_) => PanelMoreSheet(tabs: tabs, current: current),
  );

  @override
  Widget build(BuildContext context) {
    return DebugSheetSurface(
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  DebugStrings.dashboardMoreTitle,
                  style: monoStyle(size: 14),
                ),
              ),
              for (final (i, tab) in tabs.indexed) ...[
                if (i > 0) const Divider(height: 1, color: DebugColors.border),
                ListTile(
                  leading: Icon(tab.icon, size: 20, color: tab.color),
                  title: Text(tab.title, style: monoStyle(size: 13)),
                  trailing: tab.route == current
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: DebugColors.success,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(tab.route),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
