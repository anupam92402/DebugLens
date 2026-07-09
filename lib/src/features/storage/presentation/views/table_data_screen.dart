import 'package:flutter/material.dart';

import '../../data/debug_database_source.dart';
import '../../domain/table_data.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Route arguments for [TableDataScreen] — the database to read from and the
/// table within it.
class DatabaseTableArgs {
  final DebugLensDatabase database;
  final String table;

  const DatabaseTableArgs(this.database, this.table);
}

/// Shows all rows of a single table in a scrollable `DataTable`. Data is loaded
/// async (once per visit).
class TableDataScreen extends StatefulWidget {
  final DebugLensDatabase database;
  final String table;

  const TableDataScreen({
    super.key,
    required this.database,
    required this.table,
  });

  @override
  State<TableDataScreen> createState() => _TableDataScreenState();
}

class _TableDataScreenState extends State<TableDataScreen> {
  late final Future<DebugLensTableData> _future = widget.database.tableData(
    widget.table,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.table, style: monoStyle(size: 15))),
      body: FutureBuilder<DebugLensTableData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              message: DebugStrings.storageTableLoadFailed(snapshot.error),
            );
          }
          final data = snapshot.data ?? DebugLensTableData.empty;
          if (data.columns.isEmpty) {
            return const EmptyState(
              icon: Icons.table_chart,
              message: DebugStrings.storageNoColumns,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  DebugStrings.storageRowCount(data.rowCount),
                  style: monoStyle(size: 12, color: DebugPalette.textMuted),
                ),
              ),
              const Divider(height: 1, color: DebugPalette.border),
              Expanded(
                child: data.rows.isEmpty
                    ? const EmptyState(
                        icon: Icons.inbox,
                        message: DebugStrings.storageTableEmpty,
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: [
                              for (final c in data.columns)
                                DataColumn(
                                  label: Text(c, style: monoStyle(size: 11)),
                                ),
                            ],
                            rows: [
                              for (final row in data.rows)
                                DataRow(
                                  cells: [
                                    for (
                                      var i = 0;
                                      i < data.columns.length;
                                      i++
                                    )
                                      DataCell(
                                        Text(
                                          i < row.length ? row[i] : '',
                                          style: monoStyle(size: 12),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
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
