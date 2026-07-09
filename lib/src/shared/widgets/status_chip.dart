import 'package:flutter/material.dart';

import 'text_styles.dart';

/// Small colored pill used for HTTP methods, status codes, log levels, etc.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const StatusChip(
    this.label, {
    super.key,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: monoStyle(
          size: 11,
          weight: FontWeight.w700,
          color: filled ? Colors.black : color,
        ),
      ),
    );
  }
}
