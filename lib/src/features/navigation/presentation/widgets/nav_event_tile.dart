import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/nav_event.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/sequence_badge.dart';
import 'arguments_block.dart';
import '../../../../shared/theme/debug_colors.dart';

/// One expandable row in the Navigation Events tab.
///
/// Collapsed: sequence badge, action chip, kind chip (when non-page),
/// route name + time. Expanded: KV rows for navigator label / from / to,
/// plus a JSON viewer for the route arguments if any.
class NavEventTile extends StatelessWidget {
  final NavEvent event;

  const NavEventTile({super.key, required this.event});

  void _copy(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    DebugToast.show(context, message);
  }

  /// Renders arbitrary `arguments` to a pretty-printed JSON string so the
  /// copy button always produces something pasteable. Non-JSON values fall
  /// back to `toString()` — same shape as how the store snapshots them.
  String _argsToString(Object? args) {
    if (args == null) return '';
    try {
      return const JsonEncoder.withIndent('  ').convert(args);
    } catch (_) {
      return args.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionTone = toneForNavAction(event.action);
    return ExpansionTile(
      leading: SequenceBadge('#${event.sequence}'),
      title: Row(
        children: [
          StatusChip(event.actionLabel, color: actionTone),
          const SizedBox(width: 8),
          if (event.kind != NavRouteKind.page) ...[
            StatusChip(event.kindLabel, color: toneForNavKind(event.kind)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              event.routeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(size: 13),
            ),
          ),
          if (event.routeName.startsWith(DebugRoutes.prefix)) ...[
            const SizedBox(width: 8),
            StatusChip(
              DebugStrings.navigationInternalLabel,
              color: DebugColors.base,
            ),
          ],
        ],
      ),
      subtitle: Text(
        formatClock(event.time),
        style: monoStyle(size: 11, color: DebugColors.textMuted),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        if (event.navigator != 'root')
          KvRow(
            label: DebugStrings.navigationLabelNavigator,
            value: event.navigator,
          ),
        KvRow(
          label: DebugStrings.navigationFrom,
          value: event.previousRoute ?? DebugConstants.emptyValue,
          onCopy: _copy,
        ),
        KvRow(
          label: DebugStrings.navigationTo,
          value: event.routeName,
          onCopy: _copy,
        ),
        const SizedBox(height: 8),
        if (event.arguments == null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              DebugStrings.navigationNoArguments,
              style: monoStyle(size: 12, color: DebugColors.textMuted),
            ),
          )
        else
          ArgumentsBlock(
            arguments: event.arguments,
            asText: _argsToString,
            onCopy: _copy,
          ),
      ],
    );
  }
}
