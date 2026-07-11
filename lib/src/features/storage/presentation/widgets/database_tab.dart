import 'package:flutter/material.dart';

import '../../data/debug_database_source.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

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
    final databases = q.isEmpty
        ? all
        : all.where((d) => d.name.toLowerCase().contains(q)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: DebugSearchField(
            hint: DebugStrings.storageSearchDatabases,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: databases.isEmpty
              ? EmptyState(
                  icon: Icons.storage,
                  message: all.isEmpty
                      ? DebugStrings.storageNoDatabases
                      : DebugStrings.commonNoMatches,
                )
              : ListView.separated(
                  itemCount: databases.length,
                  separatorBuilder: (_, __) =>
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
                ),
        ),
      ],
    );
  }
}
