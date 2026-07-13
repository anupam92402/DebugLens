import 'package:flutter/material.dart';

import '../../domain/deeplink_entry.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'deeplink_tile.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Captured deep-link feed with search and a recent/alphabetical sort toggle.
/// Each row breaks the URI into its components (scheme / host / path) and
/// renders query parameters as JSON. Filter/sort state lives in notifiers so
/// only the list leaf rebuilds; the parent screen passes fresh [items].
class DeeplinksTab extends StatefulWidget {
  final List<DeeplinkEntry> items;

  const DeeplinksTab({super.key, required this.items});

  @override
  State<DeeplinksTab> createState() => _DeeplinksTabState();
}

class _DeeplinksTabState extends State<DeeplinksTab> {
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  /// True keeps the store's recent-first order; false sorts alphabetically by
  /// uri.
  final ValueNotifier<bool> _recentFirst = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _query.dispose();
    _recentFirst.dispose();
    super.dispose();
  }

  /// Applies the search filter, then the chosen sort order.
  List<DeeplinkEntry> _visible() {
    final q = _query.value.trim().toLowerCase();
    var out = widget.items.where((e) {
      if (q.isEmpty) return true;
      return e.uri.toLowerCase().contains(q) ||
          (e.source ?? '').toLowerCase().contains(q);
    }).toList();
    if (!_recentFirst.value) {
      out.sort((a, b) => a.uri.toLowerCase().compareTo(b.uri.toLowerCase()));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: DebugSearchField(
                  hint: DebugStrings.deeplinksSearchHint,
                  onChanged: (v) => _query.value = v,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _recentFirst,
                builder: (_, recent, _) => SortToggle(
                  newestFirst: recent,
                  onToggle: () => _recentFirst.value = !recent,
                  newestTooltip: DebugStrings.commonSortRecent,
                  oldestTooltip: DebugStrings.commonSortAlpha,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([_query, _recentFirst]),
            builder: (_, _) {
              final items = _visible();
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.link_off,
                  message: widget.items.isEmpty
                      ? DebugStrings.deeplinksEmpty
                      : DebugStrings.commonNoMatches,
                );
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: DebugColors.border),
                itemBuilder: (_, i) => DeeplinkTile(entry: items[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}
