import 'package:flutter/material.dart';

import '../../domain/api_call_stat.dart';
import '../../domain/network_entry.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'breakdown.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Single row on the Network → History screen: the endpoint (method + path),
/// its outcome breakdown, and the call count for the active filter.
class ApiHistoryTile extends StatelessWidget {
  final ApiCallStat stat;

  /// Active status filter — selects which count is emphasised on the right.
  /// `null` shows the total ("frequency") count.
  final NetworkStatusKind? filter;

  const ApiHistoryTile({super.key, required this.stat, this.filter});

  @override
  Widget build(BuildContext context) {
    final methodTone = toneForMethod(stat.method);
    final count = stat.countFor(filter);
    final countTone = filter == null
        ? DebugColors.textPrimary
        : toneForStatus(filter!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(stat.methodLabel, color: methodTone),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: monoStyle(size: 12),
                ),
                const SizedBox(height: 4),
                Breakdown(stat: stat),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: monoStyle(
                  size: 18,
                  weight: FontWeight.w700,
                  color: countTone,
                ),
              ),
              Text(
                count == 1
                    ? DebugStrings.networkCall
                    : DebugStrings.networkCalls,
                style: monoStyle(size: 10, color: DebugColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
