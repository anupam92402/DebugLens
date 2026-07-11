import 'package:flutter/material.dart';

import '../theme/debug_colors.dart';

/// Centered icon + message shown when a screen or list has nothing to display.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: DebugColors.textMuted),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: DebugColors.textMuted)),
        ],
      ),
    );
  }
}
