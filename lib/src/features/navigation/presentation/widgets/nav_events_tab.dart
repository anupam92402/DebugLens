import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../domain/nav_event.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'nav_event_tile.dart';
import 'nav_kind_filter_row.dart';

/// Events tab body — owns the kind-filter selection + sort order, watches
/// the store, applies filters, and renders [NavEventTile] rows.
///
/// Pulled out of `NavigationScreen` so the screen file stays a thin tab
/// host. State is local because the filter is per-session — no need to
/// persist or share with other screens.
class NavEventsTab extends StatefulWidget {
  const NavEventsTab({super.key});

  @override
  State<NavEventsTab> createState() => _NavEventsTabState();
}

class _NavEventsTabState extends State<NavEventsTab> {
  bool _newestFirst = true;
  Set<NavRouteKind> _kinds = const {};

  /// Pure filter+sort step. Pulled out so adding new filters (e.g. by
  /// navigator label later) is one place to touch.
  List<NavEvent> _applyFilters(List<NavEvent> all) {
    final filtered = _kinds.isEmpty
        ? all
        : all.where((e) => _kinds.contains(e.kind)).toList();
    return _newestFirst ? filtered.reversed.toList() : filtered;
  }

  @override
  Widget build(BuildContext context) {
    final stored = context.watch<DebugStore>().navEvents;
    final events = _applyFilters(stored);
    final filterActive = _kinds.isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: NavKindFilterRow(
                  selected: _kinds,
                  onChanged: (next) => setState(() => _kinds = next),
                ),
              ),
              IconButton(
                tooltip: _newestFirst
                    ? DebugStrings.commonSortNewest
                    : DebugStrings.commonSortOldest,
                icon: const Icon(Icons.swap_vert),
                onPressed: () => setState(() => _newestFirst = !_newestFirst),
              ),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? EmptyState(
                  icon: Icons.alt_route,
                  message: filterActive && stored.isNotEmpty
                      ? DebugStrings.commonNoMatch
                      : DebugStrings.navigationEmpty,
                )
              : ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: DebugPalette.border),
                  itemBuilder: (_, i) => NavEventTile(event: events[i]),
                ),
        ),
      ],
    );
  }
}
