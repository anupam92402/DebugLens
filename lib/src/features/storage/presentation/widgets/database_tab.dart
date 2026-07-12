import 'package:flutter/material.dart';

import '../../data/debug_database_source.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Lists every host-registered database with a name search; tapping one opens
/// its tables screen. DebugLens keeps no copy. Rebuilds (re-reading the
/// registry) whenever [refresh] fires.
class DatabaseTab extends StatefulWidget {
  const DatabaseTab({super.key, this.refresh});

  /// Fires when the screen's refresh action runs, so the DB list re-reads.
  final Listenable? refresh;

  @override
  State<DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends State<DatabaseTab> {
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refreshers = <Listenable>[
      _query,
      if (widget.refresh != null) widget.refresh!,
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: DebugSearchField(
            hint: DebugStrings.storageSearchDatabases,
            onChanged: (v) => _query.value = v,
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge(refreshers),
            builder: (context, _) {
              final all = DebugLensDatabases.sources;
              final q = _query.value.toLowerCase();
              final databases = q.isEmpty
                  ? all
                  : all.where((d) => d.name.toLowerCase().contains(q)).toList();
              if (databases.isEmpty) {
                return EmptyState(
                  icon: Icons.storage,
                  message: all.isEmpty
                      ? DebugStrings.storageNoDatabases
                      : DebugStrings.commonNoMatches,
                );
              }
              return ListView.separated(
                itemCount: databases.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: DebugColors.border),
                itemBuilder: (_, i) {
                  final db = databases[i];
                  return ListTile(
                    leading: const Icon(Icons.storage, size: 20),
                    title: Text(db.name, style: monoStyle(size: 13)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(DebugRoutes.databaseTables, arguments: db),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
