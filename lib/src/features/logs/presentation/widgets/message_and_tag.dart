import 'package:flutter/material.dart';
import '../../domain/log_record.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Two-line block — message on top, "[label] · time" below.
class MessageAndTag extends StatelessWidget {
  final DebugLogRecord record;
  final String label;

  const MessageAndTag({super.key, required this.record, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          record.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: monoStyle(size: 13),
        ),
        const SizedBox(height: 2),
        Text(
          '[$label] · ${ClockFormat.clock(record.time)}',
          style: monoStyle(size: 11, color: DebugColors.textMuted),
        ),
      ],
    );
  }
}
