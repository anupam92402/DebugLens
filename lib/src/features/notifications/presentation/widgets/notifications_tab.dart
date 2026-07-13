import 'package:flutter/material.dart';

import '../../domain/notification_entry.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'notification_tile.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Push / local notification feed with search and a recent/alphabetical sort
/// toggle. Filter/sort state lives in notifiers so only the list leaf rebuilds;
/// the parent screen watches the store and passes fresh [items].
class NotificationsTab extends StatefulWidget {
  final List<NotificationEntry> items;

  const NotificationsTab({super.key, required this.items});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  /// True keeps the store's recent-first order; false sorts alphabetically by
  /// title.
  final ValueNotifier<bool> _recentFirst = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _query.dispose();
    _recentFirst.dispose();
    super.dispose();
  }

  /// Applies the search filter, then the chosen sort order.
  List<NotificationEntry> _visible() {
    final q = _query.value.trim().toLowerCase();
    var out = widget.items.where((e) {
      if (q.isEmpty) return true;
      return (e.title ?? '').toLowerCase().contains(q) ||
          (e.body ?? '').toLowerCase().contains(q) ||
          e.source.toLowerCase().contains(q);
    }).toList();
    if (!_recentFirst.value) {
      out.sort(
        (a, b) => (a.title ?? '').toLowerCase().compareTo(
          (b.title ?? '').toLowerCase(),
        ),
      );
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
                  hint: DebugStrings.notificationsSearchHint,
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
                  icon: Icons.notifications_off,
                  message: widget.items.isEmpty
                      ? DebugStrings.notificationsEmpty
                      : DebugStrings.commonNoMatches,
                );
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: DebugColors.border),
                itemBuilder: (_, i) => NotificationTile(entry: items[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}
