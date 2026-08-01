import 'package:flutter/material.dart';

import '../../domain/log_record.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../widgets/error_card.dart';
import '../widgets/message_card.dart';
import '../widgets/stack_card.dart';
import '../widgets/summary_card.dart';

/// Drill-down view for a single [DebugLogRecord].
class LogDetailScreen extends StatelessWidget {
  final DebugLogRecord record;

  const LogDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            StatusChip(
              record.levelLabel,
              color: toneForLevel(record.level),
              filled: true,
            ),
            const SizedBox(width: 8),
            const Text(DebugStrings.logsDetailTitle),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          SummaryCard(record: record),
          MessageCard(message: record.message),
          if (record.error != null) ErrorCard(error: record.error!),
          if (record.stackTrace != null)
            StackCard(stackTrace: record.stackTrace!),
        ],
      ),
    );
  }
}
