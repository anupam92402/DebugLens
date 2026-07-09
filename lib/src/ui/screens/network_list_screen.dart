import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/debug_store.dart';
import '../../core/models/network_entry.dart';
import '../../routing/debug_routes.dart';
import '../theme/debug_theme.dart';
import '../widgets/debug_toast.dart';
import '../widgets/debug_widgets.dart';
import '../widgets/network/connectivity_indicator.dart';
import '../widgets/network/network_status_filter_row.dart';
import '../widgets/network/network_tile.dart';

/// Top-level list of captured HTTP transactions. Owns the search query +
/// status filter + sort order state; delegates rendering to extracted
/// widgets under `widgets/network/`. Thin assembler — no formatting,
/// serialization, or per-row logic lives here.
class NetworkListScreen extends StatefulWidget {
  const NetworkListScreen({super.key});

  @override
  State<NetworkListScreen> createState() => _NetworkListScreenState();
}

class _NetworkListScreenState extends State<NetworkListScreen> {
  String _query = '';
  NetworkStatusKind? _filter;
  bool _newestFirst = true;

  /// Applies the current search / status filter to [all], returning a list
  /// already in the chosen sort order. Pure function — easy to unit-test
  /// once we add tests for the screen.
  List<NetworkEntry> _filtered(List<NetworkEntry> all) {
    final filtered = all.where(_matches).toList();
    return _newestFirst ? filtered.reversed.toList() : filtered;
  }

  bool _matches(NetworkEntry e) {
    if (_filter != null && e.statusKind != _filter) return false;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      if (!e.url.toLowerCase().contains(q) &&
          !e.methodLabel.toLowerCase().contains(q)) {
        return false;
      }
    }
    return true;
  }

  void _clear() {
    context.read<DebugStore>().clearNetwork();
    DebugToast.show(context, 'Network log cleared');
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<DebugStore>().network;
    final items = _filtered(all);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network'),
        actions: [
          const ConnectivityIndicator(),
          IconButton(
            tooltip: 'API call history',
            icon: const Icon(Icons.history),
            onPressed: () =>
                Navigator.of(context).pushNamed(DebugRoutes.networkHistory),
          ),
          IconButton(
            tooltip: 'Clear network log',
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
              hint: 'Search url / method',
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
                tooltip: _newestFirst
                    ? 'Newest first (tap for oldest)'
                    : 'Oldest first (tap for newest)',
                icon: const Icon(Icons.swap_vert),
                onPressed: () => setState(() => _newestFirst = !_newestFirst),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.cloud_off,
                    message: 'No requests captured',
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: DebugPalette.border),
                    itemBuilder: (_, i) => NetworkTile(
                      entry: items[i],
                      onTap: () => Navigator.of(context).pushNamed(
                        DebugRoutes.networkDetail,
                        arguments: items[i],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
