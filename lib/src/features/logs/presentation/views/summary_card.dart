import 'package:flutter/material.dart';

import '../../domain/log_record.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Metadata card on the log detail screen — level, name, source, time.
class SummaryCard extends StatelessWidget {
  final DebugLogRecord record;

  const SummaryCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: DebugStrings.logsSummaryCard,
      child: Column(
        children: [
          KvRow(label: DebugStrings.logsLabelLevel, value: record.level.name),
          KvRow(
            label: DebugStrings.logsLabelName,
            value: record.name ?? DebugConstants.emptyValue,
          ),
          KvRow(label: DebugStrings.logsLabelSource, value: record.source.name),
          KvRow(
            label: DebugStrings.logsLabelTime,
            value: ClockFormat.clock(record.time),
          ),
        ],
      ),
    );
  }
}
