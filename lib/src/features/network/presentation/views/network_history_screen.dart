import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../domain/api_call_stat.dart';
import '../../domain/network_entry.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../widgets/api_history_tile.dart';
import '../widgets/network_status_filter_row.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Network → History: every endpoint called this session with its call count.
/// Data lives in [DebugStore] for the session (survives clearing the log).
/// Sorted by call frequency; filter chips scope to a status and count by it.
class NetworkHistoryScreen extends StatefulWidget {
  const NetworkHistoryScreen({super.key});

  @override
  State<NetworkHistoryScreen> createState() => _NetworkHistoryScreenState();
}

class _NetworkHistoryScreenState extends State<NetworkHistoryScreen> {
  final ValueNotifier<String> _query = ValueNotifier<String>('');
  final ValueNotifier<NetworkStatusKind?> _filter =
      ValueNotifier<NetworkStatusKind?>(null); // null = frequency / All
  final ValueNotifier<bool> _descending = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _query.dispose();
    _filter.dispose();
    _descending.dispose();
    super.dispose();
  }

  /// Filters by search + status, then sorts by the active count (ties broken
  /// by most-recently-called). Reverses when not descending.
  List<ApiCallStat> _view(List<ApiCallStat> all) {
    final list = all.where(_matches).toList();
    list.sort((a, b) {
      final byCount = b
          .countFor(_filter.value)
          .compareTo(a.countFor(_filter.value));
      if (byCount != 0) return byCount;
      return b.lastCalled.compareTo(a.lastCalled);
    });
    return _descending.value ? list : list.reversed.toList();
  }

  bool _matches(ApiCallStat s) {
    if (_filter.value != null && s.countFor(_filter.value) == 0) return false;
    final q = _query.value.toLowerCase();
    if (q.isNotEmpty &&
        !s.path.toLowerCase().contains(q) &&
        !s.methodLabel.toLowerCase().contains(q)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<DebugStore>().apiHistory;

    return Scaffold(
      appBar: AppBar(title: const Text(DebugStrings.networkHistoryTitle)),
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
                valueListenable: _descending,
                builder: (_, descending, _) => SortToggle(
                  newestFirst: descending,
                  onToggle: () => _descending.value = !descending,
                  newestTooltip: DebugStrings.networkHistorySortDesc,
                  oldestTooltip: DebugStrings.networkHistorySortAsc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([_query, _filter, _descending]),
              builder: (context, _) {
                final items = _view(all);
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history,
                    message: DebugStrings.networkHistoryEmpty,
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: DebugColors.border),
                  itemBuilder: (_, i) =>
                      ApiHistoryTile(stat: items[i], filter: _filter.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
