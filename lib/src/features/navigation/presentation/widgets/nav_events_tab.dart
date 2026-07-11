import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../../../shell/debug_routes.dart';
import '../../domain/nav_event.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'nav_event_tile.dart';
import 'nav_kind_filter_row.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Events tab body — owns the search query, kind-filter selection, and sort
/// order, watches the store, applies filters, and renders [NavEventTile] rows.
///
/// [hideDebugLens] is owned by the screen (shared with the Stack tab) so the
/// eye toggle affects both tabs at once.
class NavEventsTab extends StatefulWidget {
  final bool hideDebugLens;

  const NavEventsTab({super.key, this.hideDebugLens = false});

  @override
  State<NavEventsTab> createState() => _NavEventsTabState();
}

class _NavEventsTabState extends State<NavEventsTab> {
  // Filter/sort state as notifiers so only the affected leaf (sort button,
  // filter row, list) rebuilds — no tab-wide setState.
  final ValueNotifier<bool> _newestFirst = ValueNotifier<bool>(true);
  final ValueNotifier<Set<NavRouteKind>> _kinds =
      ValueNotifier<Set<NavRouteKind>>(const {});
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  @override
  void dispose() {
    _newestFirst.dispose();
    _kinds.dispose();
    _query.dispose();
    super.dispose();
  }

  List<NavEvent> _visible(List<NavEvent> all) {
    final q = _query.value.trim().toLowerCase();
    Iterable<NavEvent> out = all;
    if (widget.hideDebugLens) {
      out = out.where((e) => !e.routeName.startsWith(DebugRoutes.prefix));
    }
    if (_kinds.value.isNotEmpty) {
      out = out.where((e) => _kinds.value.contains(e.kind));
    }
    if (q.isNotEmpty) {
      out = out.where(
        (e) =>
            e.routeName.toLowerCase().contains(q) ||
            (e.previousRoute ?? '').toLowerCase().contains(q),
      );
    }
    final list = out.toList();
    return _newestFirst.value ? list.reversed.toList() : list;
  }

  @override
  Widget build(BuildContext context) {
    final stored = context.watch<DebugStore>().navEvents;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: DebugSearchField(
            hint: DebugStrings.navigationSearchHint,
            onChanged: (v) => _query.value = v,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<Set<NavRouteKind>>(
                  valueListenable: _kinds,
                  builder: (_, kinds, _) => NavKindFilterRow(
                    selected: kinds,
                    onChanged: (next) => _kinds.value = next,
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _newestFirst,
                builder: (_, newest, _) => IconButton(
                  tooltip: newest
                      ? DebugStrings.commonSortNewest
                      : DebugStrings.commonSortOldest,
                  icon: const Icon(Icons.swap_vert),
                  onPressed: () => _newestFirst.value = !newest,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([_newestFirst, _kinds, _query]),
            builder: (context, _) {
              final events = _visible(stored);
              final narrowed =
                  _kinds.value.isNotEmpty ||
                  _query.value.trim().isNotEmpty ||
                  widget.hideDebugLens;
              if (events.isEmpty) {
                return EmptyState(
                  icon: Icons.alt_route,
                  message: narrowed && stored.isNotEmpty
                      ? DebugStrings.commonNoMatch
                      : DebugStrings.navigationEmpty,
                );
              }
              return ListView.separated(
                itemCount: events.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: DebugColors.border),
                itemBuilder: (_, i) => NavEventTile(event: events[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}
