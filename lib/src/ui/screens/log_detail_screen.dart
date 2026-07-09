import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/debug_lens_logger.dart';
import '../../util/log_serializer.dart';
import '../theme/debug_theme.dart';
import '../widgets/debug_toast.dart';
import '../widgets/debug_widgets.dart';

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
    Clipboard.setData(
        ClipboardData(text: LogSerializer.formatRecord(record)));
    DebugToast.show(
      context,
      'Log copied to clipboard',
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConsole = record.source == DebugLogSource.console;
    final tone =
        isConsole ? DebugPalette.console : toneForLevel(record.level);
    final badge = isConsole ? 'C' : record.levelLabel;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            StatusChip(badge, color: tone, filled: true),
            const SizedBox(width: 8),
            const Text('Log detail'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Copy full record',
            icon: const Icon(Icons.copy_all),
            onPressed: () => _copyAll(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          _SummaryCard(record: record),
          _MessageCard(message: record.message),
          if (record.error != null) _ErrorCard(error: record.error!),
          if (record.stackTrace != null)
            _StackCard(stackTrace: record.stackTrace!),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DebugLogRecord record;
  const _SummaryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Summary',
      child: Column(
        children: [
          KvRow(label: 'Level', value: record.level.name),
          KvRow(label: 'Name', value: record.name ?? '—'),
          KvRow(label: 'Source', value: record.source.name),
          KvRow(label: 'Time', value: formatClock(record.time)),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;
  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Message',
      child: SelectableText(message, style: monoStyle(size: 13)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final Object error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Error',
      child: SelectableText(
        error.toString(),
        style: monoStyle(size: 13, color: DebugPalette.error),
      ),
    );
  }
}

class _StackCard extends StatelessWidget {
  final String stackTrace;
  const _StackCard({required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Stack trace',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DebugPalette.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SelectableText(
          stackTrace,
          style: monoStyle(size: 12, color: DebugPalette.textMuted),
        ),
      ),
    );
  }
}
