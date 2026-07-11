import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/shell_cubit.dart';

/// Notched bottom bar: Home | docked FAB | APIs (3 options total).
/// Selection goes through [onSelect] so the shell can pop the active tab's
/// nested stack on a re-tap.
class ShellBottomBar extends StatelessWidget {
  const ShellBottomBar({super.key, required this.onSelect});

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final index = context.watch<ShellCubit>().state;
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          _NavItem(
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            selected: index == 0,
            onTap: () => onSelect(0),
          ),
          const SizedBox(width: 88), // room for the docked FAB
          _NavItem(
            label: 'APIs',
            icon: Icons.api_outlined,
            activeIcon: Icons.api_rounded,
            selected: index == 1,
            onTap: () => onSelect(1),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
