import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/debug_strings.dart';
import 'debug_lens_controller.dart';
import 'panel_tour_keys.dart';
import 'role_swap_button.dart';

/// App bar for every panel screen: [actions] plus a close button that exits
/// the panel, and on a tab's root screen the role tag beside [title].
class DebugAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  const DebugAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottom,
  });

  static const double _closeSize = 36;
  static const double _closeIconSize = 20;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final isRoot = !(ModalRoute.of(context)?.canPop ?? false);
    final tour = isRoot ? PanelTourKeys.maybeOf(context) : null;

    return AppBar(
      title: isRoot
          ? Row(
              children: [
                Flexible(child: title),
                const SizedBox(width: 8),
                RoleSwapButton(key: tour?.role),
              ],
            )
          : title,
      actions: [
        ...actions,
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, end: 8),
          child: IconButton(
            key: tour?.close,
            tooltip: DebugStrings.commonClose,
            icon: const Icon(Icons.close, size: _closeIconSize),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              fixedSize: const Size.square(_closeSize),
              minimumSize: const Size.square(_closeSize),
            ),
            onPressed: () => context.read<DebugLensController>().close(),
          ),
        ),
      ],
      bottom: bottom,
    );
  }
}
