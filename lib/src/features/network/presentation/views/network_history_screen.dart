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

/// Network → History: every endpoint called this session with how many times
/// it was hit. Data lives in [DebugStore] for the session only (gone on app
/// restart) and survives clearing the Network log.
///
/// Sorted by call frequency (highest first) by default; the swap button
/// reverses the order. The status chips ("frequency" = All, plus Success /
/// Error / Pending) filter to endpoints with calls of that outcome and count
/// by that outcome.
class NetworkHistoryScreen extends StatefulWidget {
  const NetworkHistoryScreen({super.key});

  @override
  State<NetworkHistoryScreen> createState() => _NetworkHistoryScreenState();
}

class _NetworkHistoryScreenState extends State<NetworkHistoryScreen> {
  String _query = '';
  NetworkStatusKind? _filter; // null = frequency / All
  bool _descending = true; // highest → lowest by default

  /// Filters by search + status, then sorts by the active count (descending by
  /// default; ties broken by most-recently-called). Reverses when not
  /// descending.
  List<ApiCallStat> _view(List<ApiCallStat> all) {
    final list = all.where(_matches).toList();
    list.sort((a, b) {
      final byCount = b.countFor(_filter).compareTo(a.countFor(_filter));
      if (byCount != 0) return byCount;
      return b.lastCalled.compareTo(a.lastCalled);
    });
    return _descending ? list : list.reversed.toList();
  }

  bool _matches(ApiCallStat s) {
    if (_filter != null && s.countFor(_filter) == 0) return false;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      if (!s.path.toLowerCase().contains(q) &&
          !s.methodLabel.toLowerCase().contains(q)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<DebugStore>().apiHistory;
    final items = _view(all);

    return Scaffold(
      appBar: AppBar(title: const Text(DebugStrings.networkHistoryTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: DebugSearchField(
              hint: DebugStrings.networkSearchHint,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: NetworkStatusFilterRow(
                  selected: _filter,
                  onSelected: (f) => setState(() => _filter = f),
                ),
              ),
              IconButton(
                tooltip: _descending
                    ? DebugStrings.networkHistorySortDesc
                    : DebugStrings.networkHistorySortAsc,
                icon: const Icon(Icons.swap_vert),
                onPressed: () => setState(() => _descending = !_descending),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.history,
                    message: DebugStrings.networkHistoryEmpty,
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: DebugColors.border),
                    itemBuilder: (_, i) =>
                        ApiHistoryTile(stat: items[i], filter: _filter),
                  ),
          ),
        ],
      ),
    );
  }
}
