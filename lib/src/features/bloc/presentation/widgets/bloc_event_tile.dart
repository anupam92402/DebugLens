import 'package:flutter/material.dart';

import '../../domain/bloc_event.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/sequence_badge.dart';
import 'error_block.dart';
import 'stack_block.dart';

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
