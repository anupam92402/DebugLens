import 'package:flutter/material.dart';
import '../../domain/api_call_stat.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Small colored count chips for the success / error / pending buckets — only
/// the non-zero ones are shown.
class Breakdown extends StatelessWidget {
  final ApiCallStat stat;

  const Breakdown({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (stat.success > 0)
        StatusChip(
          DebugStrings.networkOk(stat.success),
          color: DebugColors.success,
        ),
      if (stat.error > 0)
        StatusChip(
          DebugStrings.networkErr(stat.error),
          color: DebugColors.error,
        ),
      if (stat.pending > 0)
        StatusChip(
          DebugStrings.networkPend(stat.pending),
          color: DebugColors.pending,
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }
}
