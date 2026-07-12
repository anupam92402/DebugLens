import 'package:flutter/material.dart';

import '../../data/debug_database_source.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'table_data_screen.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Lists a database's tables (name search); tapping one opens [TableDataScreen].
/// The refresh action re-reads the table list.
class DatabaseTablesScreen extends StatefulWidget {
  final DebugLensDatabase database;

  const DatabaseTablesScreen({super.key, required this.database});

  @override
  State<DatabaseTablesScreen> createState() => _DatabaseTablesScreenState();
}

class _DatabaseTablesScreenState extends State<DatabaseTablesScreen> {
  late final ValueNotifier<Future<List<String>>> _tables = ValueNotifier(
    widget.database.tableNames(),
  );
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  @override
  void dispose() {
    _tables.dispose();
    _query.dispose();
    super.dispose();
  }

  void _reload() => _tables.value = widget.database.tableNames();

  List<String> _filter(List<String> tables) {
    final q = _query.value.toLowerCase();
    if (q.isEmpty) return tables;
    return tables.where((t) => t.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.database.name, style: monoStyle(size: 15)),
        actions: [
          IconButton(
            tooltip: DebugStrings.storageRefreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: ValueListenableBuilder<Future<List<String>>>(
        valueListenable: _tables,
        builder: (context, future, _) => FutureBuilder<List<String>>(
          future: future,
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
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: DebugSearchField(
                    hint: DebugStrings.storageSearchTables,
                    onChanged: (v) => _query.value = v,
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _query,
                    builder: (context, _, _) {
                      final tables = _filter(all);
                      if (tables.isEmpty) {
                        return EmptyState(
                          icon: Icons.table_chart,
                          message: all.isEmpty
                              ? DebugStrings.storageNoTables
                              : DebugStrings.storageNoMatchingTables,
                        );
                      }
                      return ListView.separated(
                        itemCount: tables.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: DebugColors.border),
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
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
