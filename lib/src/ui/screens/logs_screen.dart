import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/debug_lens_logger.dart';
import '../../routing/debug_routes.dart';
import '../../util/log_serializer.dart';
import '../theme/debug_theme.dart';
import '../widgets/debug_toast.dart';
import '../widgets/debug_widgets.dart';
import '../widgets/logs/log_filter_row.dart';
import '../widgets/logs/log_tile.dart';

/// Live log feed for `DebugLensLogger` records.
///
/// Owns three pieces of local state:
///   - [_query] : free-text search across message + name
///   - [_levels]: which `DebugLogLevel`s to keep (applies only to custom)
///   - [_showConsole]: whether console-sourced rows are visible
///   - [_newestFirst]: list sort order
///
/// Listens to `DebugLensLogger.instance` (a `ChangeNotifier`) via
/// `ListenableBuilder`, so this screen is the rebuild point. Tile + filter
/// row are extracted widgets.
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _query = '';
  Set<DebugLogLevel> _levels = const {};
  bool _showConsole = false;
  bool _newestFirst = true;

  /// Returns true when [record] matches the current filter combination.
  ///
  /// Console-sourced rows are gated solely by [_showConsole]. Custom rows
  /// are gated by [_levels] (empty = no narrowing). The search query
  /// applies to both groups.
  bool _matches(DebugLogRecord record) {
    if (record.source == DebugLogSource.console) {
      if (!_showConsole) return false;
    } else {
      if (_levels.isNotEmpty && !_levels.contains(record.level)) return false;
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      final inName = (record.name ?? '').toLowerCase().contains(q);
      if (!record.message.toLowerCase().contains(q) && !inName) return false;
    }
    return true;
  }

  List<DebugLogRecord> _filtered(List<DebugLogRecord> all) {
    final filtered = all.where(_matches).toList();
    return _newestFirst ? filtered.reversed.toList() : filtered;
  }

  Future<void> _shareAll(List<DebugLogRecord> records) async {
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    await SharePlus.instance.share(
      ShareParams(
        text: LogSerializer.formatBundle(records),
        subject: 'DebugLens logs ($stamp)',
      ),
    );
  }

  void _clear() {
    DebugLensLogger.instance.clear();
    DebugToast.show(context, 'Logs cleared');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DebugLensLogger.instance,
      builder: (context, _) {
        final all = DebugLensLogger.instance.history;
        final items = _filtered(all);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Logs'),
            actions: [
              IconButton(
                tooltip: 'Share logs as file',
                icon: const Icon(Icons.share),
                onPressed: all.isEmpty ? null : () => _shareAll(all),
              ),
              IconButton(
                tooltip: 'Clear logs',
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
                  hint: 'Search message / name',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: LogFilterRow(
                      selectedLevels: _levels,
                      showConsole: _showConsole,
                      onLevelsChanged: (next) =>
                          setState(() => _levels = next),
                      onShowConsoleChanged: (next) =>
                          setState(() => _showConsole = next),
                    ),
                  ),
                  IconButton(
                    tooltip: _newestFirst
                        ? 'Newest first (tap for oldest)'
                        : 'Oldest first (tap for newest)',
                    icon: const Icon(Icons.swap_vert),
                    onPressed: () =>
                        setState(() => _newestFirst = !_newestFirst),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(icon: Icons.notes, message: 'No logs')
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: DebugPalette.border),
                        itemBuilder: (_, i) => LogTile(
                          record: items[i],
                          onTap: () => Navigator.of(context).pushNamed(
                            DebugRoutes.logDetail,
                            arguments: items[i],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
