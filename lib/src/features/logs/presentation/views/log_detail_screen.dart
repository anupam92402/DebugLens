import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/log_serializer.dart';
import '../../domain/log_record.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'error_card.dart';
import 'message_card.dart';
import 'stack_card.dart';
import 'summary_card.dart';

/// Drill-down view for a single [DebugLogRecord]. Three section cards:
/// Summary (metadata), Message (the actual log text), Error (when an
/// exception was passed), and Stack trace (when one was attached).
///
/// AppBar exposes a single Copy-Full action that uses the same
/// [LogSerializer.formatRecord] format as the bulk Share button on the
/// Logs screen — so the text shape is consistent across both flows.
class LogDetailScreen extends StatelessWidget {
  final DebugLogRecord record;

  const LogDetailScreen({super.key, required this.record});

  void _copyAll(BuildContext context) {
    Clipboard.setData(ClipboardData(text: LogSerializer.formatRecord(record)));
    DebugToast.show(
      context,
      DebugStrings.logsCopiedToast,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConsole = record.source == DebugLogSource.console;
    final tone = isConsole ? DebugPalette.console : toneForLevel(record.level);
    final badge = isConsole ? DebugStrings.logsConsoleBadge : record.levelLabel;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            StatusChip(badge, color: tone, filled: true),
            const SizedBox(width: 8),
            const Text(DebugStrings.logsDetailTitle),
          ],
        ),
        actions: [
          IconButton(
            tooltip: DebugStrings.logsCopyFullTooltip,
            icon: const Icon(Icons.copy_all),
            onPressed: () => _copyAll(context),
          ),
        ],
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
