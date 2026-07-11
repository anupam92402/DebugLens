import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../domain/bloc_event.dart';
import '../../../../shared/debug_strings.dart';
import '../widgets/bloc_event_tile.dart';
import '../widgets/bloc_kind_filter_row.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Live feed of Bloc/Cubit lifecycle events recorded by
/// `DebugLensBlocObserver`. Same shape as the Navigation events tab:
/// chip filters, newest/oldest toggle, expandable rows with details.
///
/// Tile + filter row live in `widgets/bloc/` — this file owns the
/// per-session filter state and the AppBar.
class BlocScreen extends StatefulWidget {
  const BlocScreen({super.key});

  @override
  State<BlocScreen> createState() => _BlocScreenState();
}

class _BlocScreenState extends State<BlocScreen> {
  bool _newestFirst = true;
  Set<BlocActionKind> _kinds = const {};
  String _blocFilter = '';

  bool _matches(BlocEvent e) {
    if (_kinds.isNotEmpty && !_kinds.contains(e.kind)) return false;
    if (_blocFilter.isNotEmpty &&
        !e.blocName.toLowerCase().contains(_blocFilter.toLowerCase())) {
      return false;
    }
    return true;
  }

  List<BlocEvent> _filtered(List<BlocEvent> all) {
    final filtered = all.where(_matches).toList();
    return _newestFirst ? filtered.reversed.toList() : filtered;
  }

  void _clear() {
    context.read<DebugStore>().clearBlocEvents();
    DebugToast.show(context, DebugStrings.blocClearedToast);
  }

  @override
  Widget build(BuildContext context) {
    final stored = context.watch<DebugStore>().blocEvents;
    final events = _filtered(stored);
    final filterActive = _kinds.isNotEmpty || _blocFilter.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(DebugStrings.blocTitle),
        actions: [
          IconButton(
            tooltip: DebugStrings.blocClearTooltip,
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
              hint: DebugStrings.blocFilterHint,
              onChanged: (v) => setState(() => _blocFilter = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: BlocKindFilterRow(
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
                    icon: Icons.stream,
                    message: filterActive && stored.isNotEmpty
                        ? DebugStrings.commonNoMatch
                        : DebugStrings.blocEmpty,
                  )
                : ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: DebugColors.border),
                    itemBuilder: (_, i) => BlocEventTile(event: events[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
