import 'package:flutter/material.dart';

import '../../../../shared/widgets/glass.dart';
import 'dash_item.dart';

/// Glass tile for one dashboard entry — tapping it opens the entry's route.
class DashCard extends StatelessWidget {
  final DashItem item;

  const DashCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.color;
    return GlassSurface(
      radius: 18,
      tint: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).pushNamed(item.route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: color, size: 22),
              ),
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
