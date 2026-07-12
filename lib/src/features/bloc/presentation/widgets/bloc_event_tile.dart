import 'package:flutter/material.dart';

import '../../domain/bloc_event.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/sequence_badge.dart';
import 'error_block.dart';
import 'stack_block.dart';
import '../../../../shared/theme/debug_colors.dart';

/// One expandable row in the Bloc events feed. Collapsed shows the badge,
/// action chip, bloc name and summary; expanded shows state/event KvRows and
/// an optional error + stack.
class BlocEventTile extends StatelessWidget {
  final BlocEvent event;

  /// 1-based position in the visible list (not the event's global sequence),
  /// so badges stay contiguous when rows are filtered out.
  final int number;

  const BlocEventTile({super.key, required this.event, required this.number});

  /// Compact one-line summary shown while the row is collapsed.
  String _summary() {
    switch (event.kind) {
      case BlocActionKind.create:
        return DebugStrings.blocSummaryCreated;
      case BlocActionKind.close:
        return DebugStrings.blocSummaryClosed;
      case BlocActionKind.event:
        return DebugStrings.blocSummaryEvent(event.event);
      case BlocActionKind.change:
        return '${event.currentState ?? DebugConstants.unknownValue} → ${event.nextState ?? DebugConstants.unknownValue}';
      case BlocActionKind.transition:
        return '${event.currentState ?? DebugConstants.unknownValue} → ${event.nextState ?? DebugConstants.unknownValue}';
      case BlocActionKind.error:
        return event.error ?? DebugStrings.blocSummaryError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = toneForBlocKind(event.kind);
    return ExpansionTile(
      leading: SequenceBadge('#$number'),
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
          '${_summary()} · ${ClockFormat.clock(event.time)}',
          style: monoStyle(size: 11, color: DebugColors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        KvRow(label: DebugStrings.blocLabelBloc, value: event.blocName),
        KvRow(label: DebugStrings.blocLabelAction, value: event.kind.name),
        if (event.event != null)
          KvRow(label: DebugStrings.blocLabelEvent, value: event.event!),
        if (event.currentState != null)
          KvRow(
            label: DebugStrings.blocLabelCurrent,
            value: event.currentState!,
          ),
        if (event.nextState != null)
          KvRow(label: DebugStrings.blocLabelNext, value: event.nextState!),
        if (event.error != null) ErrorBlock(error: event.error!),
        if (event.stackTrace != null) StackBlock(stackTrace: event.stackTrace!),
      ],
    );
  }
}
