import 'package:flutter/material.dart';

import '../../data/debug_firebase_source.dart';
import '../../domain/info_group.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../widgets/firebase_entry_tile.dart';
import 'error_state.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Shows one Firebase service's data as a flat, navigation-style list of
/// expandable rows — each key/value fact tagged with its group as a colored
/// chip. Loaded async; the AppBar refresh action re-runs
/// [DebugLensFirebaseService.load] so changing data (Remote Config,
/// Crashlytics, …) can be re-fetched without leaving the screen. Rows can be
/// searched, sorted A–Z, and copied.
class FirebaseServiceScreen extends StatefulWidget {
  final DebugLensFirebaseService service;

  const FirebaseServiceScreen({super.key, required this.service});

  @override
  State<FirebaseServiceScreen> createState() => _FirebaseServiceScreenState();
}

class _FirebaseServiceScreenState extends State<FirebaseServiceScreen> {
  late Future<List<DebugLensInfoGroup>> _future = widget.service.load();

  /// Filter/sort state as notifiers so only the list rebuilds, not the screen.
  final ValueNotifier<String> _query = ValueNotifier<String>('');
  final ValueNotifier<bool> _sortAlpha = ValueNotifier<bool>(false);

  /// Stable per-group chip colors, assigned by group order.
  static const List<Color> _palette = [
    DebugColors.network,
    DebugColors.logs,
    DebugColors.navigation,
    DebugColors.storage,
    DebugColors.device,
    DebugColors.locale,
    DebugColors.bloc,
    DebugColors.notifications,
    DebugColors.settings,
  ];

  void _reload() => setState(() => _future = widget.service.load());

  @override
  void dispose() {
    _query.dispose();
    _sortAlpha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.name, style: monoStyle(size: 15)),
        actions: [
          IconButton(
            tooltip: DebugStrings.firebaseReload,
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<List<DebugLensInfoGroup>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error, onRetry: _reload);
          }
          final groups = snapshot.data ?? const [];
          if (groups.isEmpty) {
            return const EmptyState(
              icon: Icons.local_fire_department,
              message: DebugStrings.firebaseServiceEmpty,
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: DebugSearchField(
                        hint: DebugStrings.firebaseSearchHint,
                        onChanged: (v) => _query.value = v,
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _sortAlpha,
                      builder: (_, alpha, _) => SortToggle(
                        newestFirst: alpha,
                        onToggle: () => _sortAlpha.value = !alpha,
                        newestTooltip: DebugStrings.firebaseSortAlpha,
                        oldestTooltip: DebugStrings.firebaseSortOriginal,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: Listenable.merge([_query, _sortAlpha]),
                  builder: (context, _) => _buildList(groups),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<DebugLensInfoGroup> groups) {
    final q = _query.value.trim().toLowerCase();
    final rows =
        <
          ({
            String group,
            Color color,
            String label,
            String value,
            bool sensitive,
          })
        >[];
    for (var gi = 0; gi < groups.length; gi++) {
      final group = groups[gi];
      final color = _palette[gi % _palette.length];
      var entries = group.values.entries.toList();
      if (q.isNotEmpty) {
        entries = entries
            .where(
              (e) =>
                  e.key.toLowerCase().contains(q) ||
                  e.value.toLowerCase().contains(q),
            )
            .toList();
      }
      if (_sortAlpha.value) {
        entries.sort(
          (a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()),
        );
      }
      for (final e in entries) {
        rows.add((
          group: group.title,
          color: color,
          label: e.key,
          value: e.value,
          sensitive: group.isSensitive(e.key),
        ));
      }
    }
    if (rows.isEmpty) {
      return EmptyState(
        icon: q.isEmpty ? Icons.local_fire_department : Icons.search_off,
        message: q.isEmpty
            ? DebugStrings.firebaseServiceEmpty
            : DebugStrings.commonNoMatches,
      );
    }
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: DebugColors.border),
      itemBuilder: (_, i) {
        final r = rows[i];
        return FirebaseEntryTile(
          number: i + 1,
          group: r.group,
          color: r.color,
          label: r.label,
          value: r.value,
          sensitive: r.sensitive,
        );
      },
    );
  }
}
