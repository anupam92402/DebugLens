import 'package:flutter/material.dart';

import '../../domain/activity.dart';

/// Presentation styling (icon/label/color) for each [ActivityCategory].
extension CategoryStyle on ActivityCategory {
  String get label => switch (this) {
    ActivityCategory.work => 'Work',
    ActivityCategory.personal => 'Personal',
    ActivityCategory.fitness => 'Fitness',
    ActivityCategory.finance => 'Finance',
  };

  IconData get icon => switch (this) {
    ActivityCategory.work => Icons.work_outline_rounded,
    ActivityCategory.personal => Icons.favorite_outline_rounded,
    ActivityCategory.fitness => Icons.directions_run_rounded,
    ActivityCategory.finance => Icons.account_balance_wallet_outlined,
  };

  Color get color => switch (this) {
    ActivityCategory.work => const Color(0xFF4F46E5),
    ActivityCategory.personal => const Color(0xFFDB2777),
    ActivityCategory.fitness => const Color(0xFF059669),
    ActivityCategory.finance => const Color(0xFFD97706),
  };
}
