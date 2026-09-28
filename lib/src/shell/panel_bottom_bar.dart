import 'package:flutter/material.dart';

import '../shared/debug_strings.dart';
import '../shared/theme/debug_colors.dart';
import 'panel_more_sheet.dart';
import 'panel_tab.dart';

/// The panel's bottom bar: one slot per tab in [split]'s bar, then More when
/// the rest don't fit. More keeps its label whichever of its tabs is open,
/// taking that tab's accent.
class PanelBottomBar extends StatelessWidget {
  final PanelTabSplit split;

  /// Route of the tab currently open.
  final String current;

  /// 1 shown, 0 slid away; the bottom safe area stays either way.
  final Animation<double> visibility;

  final ValueChanged<String> onSelect;

  const PanelBottomBar({
    super.key,
    required this.split,
    required this.current,
    required this.visibility,
    required this.onSelect,
  });

  /// Bar height above the bottom safe area.
  static const double height = 64;
  Future<void> _openMore(BuildContext context) async {
    final route = await PanelMoreSheet.show(
      context,
      tabs: split.more,
      current: current,
    );
    if (route != null) onSelect(route);
  }

  @override
  Widget build(BuildContext context) {
    // The open tab when it lives behind More; More wears its accent.
    final openInMore = split.more.where((t) => t.route == current).firstOrNull;
    return Material(
      color: DebugColors.glassFill,
      shape: const Border(top: BorderSide(color: DebugColors.border)),
      child: SafeArea(
        top: false,
        child: SizeTransition(
          sizeFactor: visibility,
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (final tab in split.bar)
                  Expanded(
                    child: _BarSlot(
                      icon: tab.icon,
                      label: tab.title,
                      color: tab.color,
                      active: tab.route == current,
                      onTap: () => onSelect(tab.route),
                    ),
                  ),
                if (split.more.isNotEmpty)
                  Expanded(
                    child: _BarSlot(
                      icon: Icons.more_horiz,
                      label: DebugStrings.dashboardMore,
                      color: openInMore?.color ?? DebugColors.textPrimary,
                      active: openInMore != null,
                      onTap: () => _openMore(context),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One bar slot: a tab's icon and label, with an accent line on top while
/// [active].
class _BarSlot extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _BarSlot({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  static const double _iconSize = 22;
  static const double _labelSize = 11;
  static const double _indicatorWidth = 28;
  static const double _indicatorHeight = 3;

  @override
  Widget build(BuildContext context) {
    final tone = active ? color : DebugColors.textMuted;
    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: _indicatorWidth,
              height: _indicatorHeight,
              decoration: BoxDecoration(
                color: active ? color : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(_indicatorHeight),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: _iconSize, color: tone),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: _labelSize, color: tone),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
