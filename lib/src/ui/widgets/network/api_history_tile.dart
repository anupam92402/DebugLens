import 'package:flutter/material.dart';

import '../../../core/models/api_call_stat.dart';
import '../../../core/models/network_entry.dart';
import '../../theme/debug_theme.dart';
import '../debug_widgets.dart';

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
    final countTone =
        filter == null ? DebugPalette.textPrimary : toneForStatus(filter!);

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
                _Breakdown(stat: stat),
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
                count == 1 ? 'call' : 'calls',
                style: monoStyle(size: 10, color: DebugPalette.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small colored count chips for the success / error / pending buckets — only
/// the non-zero ones are shown.
class _Breakdown extends StatelessWidget {
  final ApiCallStat stat;

  const _Breakdown({required this.stat});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (stat.success > 0)
        StatusChip('OK ${stat.success}', color: DebugPalette.success),
      if (stat.error > 0)
        StatusChip('ERR ${stat.error}', color: DebugPalette.error),
      if (stat.pending > 0)
        StatusChip('PEND ${stat.pending}', color: DebugPalette.pending),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }
}
