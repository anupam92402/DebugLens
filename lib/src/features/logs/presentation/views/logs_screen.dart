import 'package:flutter/material.dart';

import '../../data/debug_lens_logger.dart';
import '../../data/log_share.dart';
import '../../domain/log_record.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shell/debug_routes.dart';
import '../widgets/log_capture_sheet.dart';
import '../widgets/log_filter_row.dart';
import '../widgets/log_tile.dart';

/// Live feed of everything in [DebugLensLogger] — the host's own calls and
/// DebugLens's internal observers.
///
/// Filter state is held in [ValueNotifier]s rather than [State] fields so
/// typing or flipping a chip rebuilds only the affected subtree, never the
/// whole screen:
///
/// * [_query] — free-text over message + name
/// * [_levels] — which levels to keep (empty = all)
/// * [_newestFirst] — list order
///
/// The AppBar's capture action opens [LogCaptureSheet], which controls what is
/// *recorded*; the chips below control what is *shown*.
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final ValueNotifier<String> _query = ValueNotifier<String>('');
  final ValueNotifier<Set<DebugLogLevel>> _levels =
      ValueNotifier<Set<DebugLogLevel>>(const {});
  final ValueNotifier<bool> _newestFirst = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _query.dispose();
    _levels.dispose();
    _newestFirst.dispose();
    super.dispose();
  }

  /// Whether [record] survives the current filter combination — the selected
  /// levels (empty = no narrowing) and the search query.
  bool _matches(DebugLogRecord record) {
    final levels = _levels.value;
    if (levels.isNotEmpty && !levels.contains(record.level)) return false;
    final q = _query.value.trim().toLowerCase();
    if (q.isEmpty) return true;
    return record.message.toLowerCase().contains(q) ||
        (record.name ?? '').toLowerCase().contains(q);
  }

  List<DebugLogRecord> _filtered(List<DebugLogRecord> all) {
    final matched = all.where(_matches).toList();
    return _newestFirst.value ? matched.reversed.toList() : matched;
  }

  /// Shares the whole buffer as a log file — including records whose origin
  /// has since been switched off, which stay in history precisely so they
  /// remain exportable.
  Future<void> _shareAll(BuildContext context, List<DebugLogRecord> records) {
    final box = context.findRenderObject() as RenderBox?;
    return LogShare.share(
      records,
      origin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  void _clear() {
    DebugLensLogger.instance.clear();
    DebugToast.show(context, DebugStrings.logsClearedToast);
  }

  @override
  Widget build(BuildContext context) {
    final logger = DebugLensLogger.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text(DebugStrings.logsTitle),
        actions: [
          IconButton(
            tooltip: DebugStrings.logsCaptureTooltip,
            icon: const Icon(Icons.tune),
            onPressed: () => LogCaptureSheet.show(context),
          ),

          /// Only the Share button depends on the buffer, so it alone listens.
          ListenableBuilder(
            listenable: logger,
            builder: (_, _) {
              final all = logger.history;
              return IconButton(
                tooltip: DebugStrings.logsShareTooltip,
                icon: const Icon(Icons.share),
                onPressed: all.isEmpty ? null : () => _shareAll(context, all),
              );
            },
          ),
          IconButton(
            tooltip: DebugStrings.logsClearTooltip,
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
              hint: DebugStrings.logsSearchHint,
              onChanged: (v) => _query.value = v,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<Set<DebugLogLevel>>(
                  valueListenable: _levels,
                  builder: (_, levels, _) => LogFilterRow(
                    selectedLevels: levels,
                    onLevelsChanged: (next) => _levels.value = next,
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _newestFirst,
                builder: (_, newestFirst, _) => IconButton(
                  tooltip: newestFirst
                      ? DebugStrings.commonSortNewest
                      : DebugStrings.commonSortOldest,
                  icon: const Icon(Icons.swap_vert),
                  onPressed: () => _newestFirst.value = !newestFirst,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                logger,
                _query,
                _levels,
                _newestFirst,
              ]),
              builder: (context, _) => _buildList(logger.history),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<DebugLogRecord> all) {
    final items = _filtered(all);
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.notes,
        message: DebugStrings.logsEmpty,
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: DebugColors.border),
      itemBuilder: (_, i) => LogTile(
        record: items[i],
        onTap: () => Navigator.of(
          context,
        ).pushNamed(DebugRoutes.logDetail, arguments: items[i]),
      ),
    );
  }
}
