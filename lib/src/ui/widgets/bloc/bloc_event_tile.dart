import 'package:flutter/material.dart';

import '../../../core/models/bloc_event.dart';
import '../../theme/debug_theme.dart';
import '../debug_widgets.dart';
import '../sequence_badge.dart';

/// One expandable row in the Bloc events feed.
///
/// Collapsed: sequence badge + action chip + bloc name + summary line.
/// Expanded: structured KvRows for current/next state + event, plus an
/// optional ERROR + STACK pair when the underlying record carries an
/// exception.
class BlocEventTile extends StatelessWidget {
  final BlocEvent event;

  const BlocEventTile({super.key, required this.event});

  /// Compact summary shown when the row is collapsed, so users can read
  /// the timeline without expanding everything.
  String _summary() {
    switch (event.kind) {
      case BlocActionKind.create:
        return 'created';
      case BlocActionKind.close:
        return 'closed';
      case BlocActionKind.event:
        return 'event · ${event.event ?? '—'}';
      case BlocActionKind.change:
        return '${event.currentState ?? '?'} → ${event.nextState ?? '?'}';
      case BlocActionKind.transition:
        return '${event.currentState ?? '?'} → ${event.nextState ?? '?'}';
      case BlocActionKind.error:
        return event.error ?? 'error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = toneForBlocKind(event.kind);
    return ExpansionTile(
      leading: SequenceBadge('#${event.sequence}'),
      title: Row(
        children: [
          StatusChip(event.kindLabel, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.blocName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(size: 13),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '${_summary()} · ${formatClock(event.time)}',
          style: monoStyle(size: 11, color: DebugPalette.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        KvRow(label: 'bloc', value: event.blocName),
        KvRow(label: 'action', value: event.kind.name),
        if (event.event != null) KvRow(label: 'event', value: event.event!),
        if (event.currentState != null)
          KvRow(label: 'current', value: event.currentState!),
        if (event.nextState != null)
          KvRow(label: 'next', value: event.nextState!),
        if (event.error != null) _ErrorBlock(error: event.error!),
        if (event.stackTrace != null) _StackBlock(stackTrace: event.stackTrace!),
      ],
    );
  }
}

/// Red "ERROR" section header + the error text below it. Used when the
/// underlying bloc threw an uncaught exception.
class _ErrorBlock extends StatelessWidget {
  final String error;

  const _ErrorBlock({required this.error});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          'ERROR',
          style: monoStyle(
              size: 11,
              weight: FontWeight.w700,
              color: DebugPalette.error),
        ),
        const SizedBox(height: 4),
        SelectableText(
          error,
          style: monoStyle(size: 12, color: DebugPalette.error),
        ),
      ],
    );
  }
}

/// Muted "STACK" header + a code-style container with the stack trace.
/// Always paired with [_ErrorBlock] in practice.
class _StackBlock extends StatelessWidget {
  final String stackTrace;

  const _StackBlock({required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'STACK',
          style: monoStyle(
              size: 11,
              weight: FontWeight.w700,
              color: DebugPalette.textMuted),
        ),
        const SizedBox(height: 4),
        Container(
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
      ],
    );
  }
}
