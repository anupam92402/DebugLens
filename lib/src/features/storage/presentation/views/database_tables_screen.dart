import 'package:flutter/material.dart';

import '../../data/debug_database_source.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'table_data_screen.dart';

/// Lists every table in a [DebugLensDatabase] in a vertical list, with a search
/// field that filters by table name. Tapping a table opens [TableDataScreen].
/// Tables are loaded async (once per visit).
class DatabaseTablesScreen extends StatefulWidget {
  final DebugLensDatabase database;

  const DatabaseTablesScreen({super.key, required this.database});

  @override
  State<DatabaseTablesScreen> createState() => _DatabaseTablesScreenState();
}

class _DatabaseTablesScreenState extends State<DatabaseTablesScreen> {
  late final Future<List<String>> _future = widget.database.tableNames();
  String _query = '';

  List<String> _filter(List<String> tables) {
    if (_query.isEmpty) return tables;
    final q = _query.toLowerCase();
    return tables.where((t) => t.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.database.name, style: monoStyle(size: 15)),
      ),
      body: FutureBuilder<List<String>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              message: DebugStrings.storageTablesLoadFailed(snapshot.error),
            );
          }
          final all = snapshot.data ?? const [];
          final tables = _filter(all);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: DebugSearchField(
                  hint: DebugStrings.storageSearchTables,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: tables.isEmpty
                    ? EmptyState(
                        icon: Icons.table_chart,
                        message: all.isEmpty
                            ? DebugStrings.storageNoTables
                            : DebugStrings.storageNoMatchingTables,
                      )
                    : ListView.separated(
                        itemCount: tables.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: DebugPalette.border,
                        ),
                        itemBuilder: (_, i) => ListTile(
                          leading: const Icon(Icons.table_rows, size: 20),
                          title: Text(tables[i], style: monoStyle(size: 13)),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () => Navigator.of(context).pushNamed(
                            DebugRoutes.databaseData,
                            arguments: DatabaseTableArgs(
                              widget.database,
                              tables[i],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
