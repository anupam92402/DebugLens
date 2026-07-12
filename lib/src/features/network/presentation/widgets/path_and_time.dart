import 'package:flutter/material.dart';
import '../../domain/network_entry.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Two-line label inside the tile — endpoint path on top, then
/// time · duration with the status chip to its right.
class PathAndTime extends StatelessWidget {
  final NetworkEntry entry;
  final String duration;
  final String statusText;
  final Color statusTone;

  const PathAndTime({
    super.key,
    required this.entry,
    required this.duration,
    required this.statusText,
    required this.statusTone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.path,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: monoStyle(size: 12),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            StatusChip(statusText, color: statusTone),
            const SizedBox(width: 8),
            Text(
              '${ClockFormat.clock(entry.requestTime)} · $duration',
              style: monoStyle(size: 11, color: DebugColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
