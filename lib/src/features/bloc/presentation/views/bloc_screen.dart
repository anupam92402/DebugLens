import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../data/bloc_log_share.dart';
import '../../domain/bloc_event.dart';
import '../../domain/numbered_bloc_event.dart';
import '../../../../shared/debug_strings.dart';
import '../widgets/bloc_event_tile.dart';
import '../widgets/bloc_kind_filter_row.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Live feed of Bloc/Cubit lifecycle events recorded by
/// `DebugLensBlocObserver` — chip filters, sort toggle, expandable rows.
class BlocScreen extends StatefulWidget {
  const BlocScreen({super.key});

  @override
  State<BlocScreen> createState() => _BlocScreenState();
}

class _BlocScreenState extends State<BlocScreen> {
  // Filter/sort state as notifiers so only the dependent leaves rebuild.
  final ValueNotifier<bool> _newestFirst = ValueNotifier<bool>(true);
  final ValueNotifier<Set<BlocActionKind>> _kinds =
      ValueNotifier<Set<BlocActionKind>>(const {});
  final ValueNotifier<String> _blocFilter = ValueNotifier<String>('');

  @override
  void dispose() {
    _newestFirst.dispose();
    _kinds.dispose();
    _blocFilter.dispose();
    super.dispose();
  }

  bool _matches(BlocEvent e) {
    if (_kinds.value.isNotEmpty && !_kinds.value.contains(e.kind)) return false;
    final q = _blocFilter.value.toLowerCase();
    if (q.isNotEmpty && !e.blocName.toLowerCase().contains(q)) return false;
    return true;
  }

  /// Filters, then numbers by position (oldest = 1) so badges stay contiguous
  /// whatever is hidden and stable across a sort flip.
  List<NumberedBlocEvent> _visible(List<BlocEvent> all) {
    final filtered = all.where(_matches).toList();
    final numbered = [
      for (var i = 0; i < filtered.length; i++)
        NumberedBlocEvent(filtered[i], i + 1),
    ];
    return _newestFirst.value ? numbered.reversed.toList() : numbered;
  }

  void _clear() {
    context.read<DebugStore>().clearBlocEvents();
    DebugToast.show(context, DebugStrings.blocClearedToast);
  }

  Future<void> _share() {
    final box = context.findRenderObject() as RenderBox?;
    return BlocLogShare.share(
      context.read<DebugStore>(),
      origin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stored = context.watch<DebugStore>().blocEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text(DebugStrings.blocTitle),
        actions: [
          IconButton(
            tooltip: DebugStrings.blocShareTooltip,
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
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
              onChanged: (v) => _blocFilter.value = v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<Set<BlocActionKind>>(
                    valueListenable: _kinds,
                    builder: (_, kinds, _) => BlocKindFilterRow(
                      selected: kinds,
                      onChanged: (next) => _kinds.value = next,
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
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([_newestFirst, _kinds, _blocFilter]),
              builder: (context, _) {
                final events = _visible(stored);
                final filterActive =
                    _kinds.value.isNotEmpty || _blocFilter.value.isNotEmpty;
                if (events.isEmpty) {
                  return EmptyState(
                    icon: Icons.stream,
                    message: filterActive && stored.isNotEmpty
                        ? DebugStrings.commonNoMatch
                        : DebugStrings.blocEmpty,
                  );
                }
                return ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: DebugColors.border),
                  itemBuilder: (_, i) => BlocEventTile(
                    event: events[i].event,
                    number: events[i].number,
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
