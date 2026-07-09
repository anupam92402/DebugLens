import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/nav_event.dart';
import '../../theme/debug_theme.dart';
import '../debug_toast.dart';
import '../debug_widgets.dart';
import '../json_view.dart';
import '../sequence_badge.dart';

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
        ],
      ),
      subtitle: Text(
        formatClock(event.time),
        style: monoStyle(size: 11, color: DebugPalette.textMuted),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        if (event.navigator != 'root')
          KvRow(label: 'navigator', value: event.navigator),
        _CopyableKvRow(
          label: 'from',
          value: event.previousRoute ?? '—',
          onCopy: _copy,
        ),
        _CopyableKvRow(
          label: 'to',
          value: event.routeName,
          onCopy: _copy,
        ),
        const SizedBox(height: 8),
        if (event.arguments == null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('no arguments',
                style: monoStyle(size: 12, color: DebugPalette.textMuted)),
          )
        else
          _ArgumentsBlock(
            arguments: event.arguments,
            asText: _argsToString,
            onCopy: _copy,
          ),
      ],
    );
  }
}

/// KV row with a trailing copy icon — used for the from/to labels so each
/// route name is one tap to clipboard.
class _CopyableKvRow extends StatelessWidget {
  final String label;
  final String value;
  final void Function(BuildContext, String, String) onCopy;

  const _CopyableKvRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: KvRow(label: label, value: value)),
        _CopyIcon(
          tooltip: 'Copy $label',
          onTap: () => onCopy(context, value, '"$label" copied'),
        ),
      ],
    );
  }
}

/// "ARGUMENTS" header + copy button + JSON-pretty body. Extracted because
/// the same shape is reused for any future tile that wants a labeled
/// JSON block with copy.
class _ArgumentsBlock extends StatelessWidget {
  final Object? arguments;
  final String Function(Object?) asText;
  final void Function(BuildContext, String, String) onCopy;

  const _ArgumentsBlock({
    required this.arguments,
    required this.asText,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ARGUMENTS',
              style: monoStyle(
                  size: 11,
                  weight: FontWeight.w700,
                  color: DebugPalette.textMuted),
            ),
            const Spacer(),
            _CopyIcon(
              tooltip: 'Copy arguments',
              onTap: () => onCopy(
                  context, asText(arguments), 'Arguments copied'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        JsonView(arguments),
      ],
    );
  }
}

/// Compact 16-px copy icon, used inline in expansion content.
class _CopyIcon extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;

  const _CopyIcon({required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(),
      color: DebugPalette.textMuted,
      icon: const Icon(Icons.copy, size: 16),
      onPressed: onTap,
    );
  }
}
