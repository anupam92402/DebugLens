import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/sequence_badge.dart';

/// One row in [ApiCallsSheet]: a call's position, its clock time, and how long
/// after the previous call it fired.
///
/// [sincePrevious] is null for the oldest retained call — nothing precedes it,
/// so there is no gap to show.
class ApiCallRow extends StatelessWidget {
  final int number;
  final DateTime at;
  final Duration? sincePrevious;

  const ApiCallRow({
    super.key,
    required this.number,
    required this.at,
    required this.sincePrevious,
  });

  @override
  Widget build(BuildContext context) {
    final gap = sincePrevious;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SequenceBadge('#$number'),
          const SizedBox(width: 12),
          Expanded(
            child: Text(ClockFormat.clock(at), style: monoStyle(size: 12)),
          ),
          Text(
            gap == null
                ? DebugStrings.networkFirstCall
                : '+${ClockFormat.gap(gap)}',
            style: monoStyle(
              size: 12,
              color: gap == null ? DebugColors.textMuted : DebugColors.pending,
            ),
          ),
        ],
      ),
    );
  }
}
