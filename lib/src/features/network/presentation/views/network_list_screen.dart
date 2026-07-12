import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../domain/network_entry.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../widgets/connectivity_indicator.dart';
import '../widgets/network_status_filter_row.dart';
import '../widgets/network_tile.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Top-level list of captured HTTP transactions. Owns the search/filter/sort
/// state (as notifiers, so only the list rebuilds) and delegates rendering to
/// extracted widgets.
class NetworkListScreen extends StatefulWidget {
  const NetworkListScreen({super.key});

  @override
  State<NetworkListScreen> createState() => _NetworkListScreenState();
}

class _NetworkListScreenState extends State<NetworkListScreen> {
  final ValueNotifier<String> _query = ValueNotifier<String>('');
  final ValueNotifier<NetworkStatusKind?> _filter =
      ValueNotifier<NetworkStatusKind?>(null);
  final ValueNotifier<bool> _newestFirst = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _query.dispose();
    _filter.dispose();
    _newestFirst.dispose();
    super.dispose();
  }

  /// Applies the current search/status filter, returning the list already in
  /// the chosen sort order.
  List<NetworkEntry> _filtered(List<NetworkEntry> all) {
    final filtered = all.where(_matches).toList();
    return _newestFirst.value ? filtered.reversed.toList() : filtered;
  }

  bool _matches(NetworkEntry e) {
    if (_filter.value != null && e.statusKind != _filter.value) return false;
    final q = _query.value.toLowerCase();
    if (q.isNotEmpty &&
        !e.url.toLowerCase().contains(q) &&
        !e.methodLabel.toLowerCase().contains(q)) {
      return false;
    }
    return true;
  }

  void _clear() {
    context.read<DebugStore>().clearNetwork();
    DebugToast.show(context, DebugStrings.networkClearedToast);
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<DebugStore>().network;

    return Scaffold(
      appBar: AppBar(
        title: const Text(DebugStrings.networkTitle),
        actions: [
          const ConnectivityIndicator(),
          IconButton(
            tooltip: DebugStrings.networkHistoryTooltip,
            icon: const Icon(Icons.history),
            onPressed: () =>
                Navigator.of(context).pushNamed(DebugRoutes.networkHistory),
          ),
          IconButton(
            tooltip: DebugStrings.networkClearTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: _clear,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: DebugSearchField(
              hint: DebugStrings.networkSearchHint,
              onChanged: (v) => _query.value = v,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<NetworkStatusKind?>(
                  valueListenable: _filter,
                  builder: (_, filter, _) => NetworkStatusFilterRow(
                    selected: filter,
                    onSelected: (f) => _filter.value = f,
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _newestFirst,
                builder: (_, newest, _) => SortToggle(
                  newestFirst: newest,
                  onToggle: () => _newestFirst.value = !newest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([_query, _filter, _newestFirst]),
              builder: (context, _) {
                final items = _filtered(all);
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.cloud_off,
                    message: DebugStrings.networkEmpty,
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: DebugColors.border),
                  itemBuilder: (_, i) => NetworkTile(
                    entry: items[i],
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(DebugRoutes.networkDetail, arguments: items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
