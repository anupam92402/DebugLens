import 'package:flutter/material.dart';

import '../../../core/models/deeplink_entry.dart';
import '../../theme/debug_theme.dart';
import '../debug_widgets.dart';
import '../json_view.dart';

/// Captured deep-link feed. Each row breaks the URI into its components
/// (scheme / host / path) and renders query parameters as JSON.
class DeeplinksTab extends StatelessWidget {
  final List<DeeplinkEntry> items;

  const DeeplinksTab({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(icon: Icons.link_off, message: 'No deeplinks');
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: DebugPalette.border),
      itemBuilder: (_, i) => _DeeplinkTile(entry: items[i]),
    );
  }
}

class _DeeplinkTile extends StatelessWidget {
  final DeeplinkEntry entry;

  const _DeeplinkTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final uri = entry.parsed;
    return ExpansionTile(
      leading: const Icon(Icons.link),
      title: Text(
        entry.uri,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: monoStyle(size: 13),
      ),
      subtitle: Text(
        '${entry.source ?? 'unknown'} · ${formatClock(entry.time)}',
        style: monoStyle(size: 11, color: DebugPalette.textMuted),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        KvRow(label: 'scheme', value: uri?.scheme ?? '—'),
        KvRow(label: 'host', value: uri?.host ?? '—'),
        KvRow(label: 'path', value: uri?.path ?? '—'),
        const SizedBox(height: 8),
        if (entry.queryParameters.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('no query params',
                style: monoStyle(size: 12, color: DebugPalette.textMuted)),
          )
        else
          JsonView(entry.queryParameters),
      ],
    );
  }
}
