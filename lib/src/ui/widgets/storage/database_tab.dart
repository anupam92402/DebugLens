import 'package:flutter/material.dart';

import '../../../core/debug_database_source.dart';
import '../../../routing/debug_routes.dart';
import '../../theme/debug_theme.dart';
import '../debug_widgets.dart';

/// Lists every registered database (vertical) with a search field on top.
/// Tapping a database opens its tables screen. Databases come from the
/// host-registered [DebugLensDatabases.sources]; DebugLens keeps no copy.
class DatabaseTab extends StatefulWidget {
  const DatabaseTab({super.key});

  @override
  State<DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends State<DatabaseTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = DebugLensDatabases.sources;
    final q = _query.toLowerCase();
    final databases =
        q.isEmpty ? all : all.where((d) => d.name.toLowerCase().contains(q)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: DebugSearchField(
            hint: 'Search databases',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: databases.isEmpty
              ? EmptyState(
                  icon: Icons.storage,
                  message: all.isEmpty ? 'No databases' : 'No matches',
                )
              : ListView.separated(
                  itemCount: databases.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: DebugPalette.border),
                  itemBuilder: (_, i) {
                    final db = databases[i];
                    return ListTile(
                      leading: const Icon(Icons.storage, size: 20),
                      title: Text(db.name, style: monoStyle(size: 13)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => Navigator.of(context).pushNamed(
                        DebugRoutes.databaseTables,
                        arguments: db,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
