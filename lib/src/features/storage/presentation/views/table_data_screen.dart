import 'package:flutter/material.dart';

import '../../data/debug_database_source.dart';
import '../../domain/table_data.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Route arguments for [TableDataScreen] — the database to read from and the
/// table within it.
class DatabaseTableArgs {
  final DebugLensDatabase database;
  final String table;

  const DatabaseTableArgs(this.database, this.table);
}

/// Shows a table's rows in a scrollable `DataTable` with row search and
/// tap-to-sort columns. The refresh action re-reads the table.
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
  late final ValueNotifier<Future<DebugLensTableData>> _data = ValueNotifier(
    widget.database.tableData(widget.table),
  );
  final ValueNotifier<String> _query = ValueNotifier<String>('');
  final ValueNotifier<int?> _sortColumn = ValueNotifier<int?>(null);
  final ValueNotifier<bool> _ascending = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _data.dispose();
    _query.dispose();
    _sortColumn.dispose();
    _ascending.dispose();
    super.dispose();
  }

  void _reload() => _data.value = widget.database.tableData(widget.table);

  /// Filters rows by the query (any cell), then sorts by the active column.
  List<List<String>> _view(DebugLensTableData data) {
    final q = _query.value.toLowerCase();
    var rows = q.isEmpty
        ? data.rows
        : data.rows
              .where((r) => r.any((c) => c.toLowerCase().contains(q)))
              .toList();
    final col = _sortColumn.value;
    if (col != null) {
      rows = [...rows]
        ..sort((a, b) {
          final cmp = _compare(
            col < a.length ? a[col] : '',
            col < b.length ? b[col] : '',
          );
          return _ascending.value ? cmp : -cmp;
        });
    }
    return rows;
  }

  /// Numeric-aware comparison so `id`-style columns sort as numbers.
  int _compare(String a, String b) {
    final na = num.tryParse(a);
    final nb = num.tryParse(b);
    if (na != null && nb != null) return na.compareTo(nb);
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  void _onSort(int columnIndex, bool ascending) {
    _sortColumn.value = columnIndex;
    _ascending.value = ascending;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.table, style: monoStyle(size: 15)),
        actions: [
          IconButton(
            tooltip: DebugStrings.storageRefreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: ValueListenableBuilder<Future<DebugLensTableData>>(
        valueListenable: _data,
        builder: (context, future, _) => FutureBuilder<DebugLensTableData>(
          future: future,
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: DebugSearchField(
                    hint: DebugStrings.storageSearchRows,
                    onChanged: (v) => _query.value = v,
                  ),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      _query,
                      _sortColumn,
                      _ascending,
                    ]),
                    builder: (context, _) => _table(data),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _table(DebugLensTableData data) {
    final rows = _view(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            DebugStrings.storageRowCount(rows.length),
            style: monoStyle(size: 12, color: DebugColors.textMuted),
          ),
        ),
        const Divider(height: 1, color: DebugColors.border),
        Expanded(
          child: rows.isEmpty
              ? EmptyState(
                  icon: data.rows.isEmpty ? Icons.inbox : Icons.search_off,
                  message: data.rows.isEmpty
                      ? DebugStrings.storageTableEmpty
                      : DebugStrings.commonNoMatches,
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      sortColumnIndex: _sortColumn.value,
                      sortAscending: _ascending.value,
                      columns: [
                        for (final c in data.columns)
                          DataColumn(
                            label: Text(c, style: monoStyle(size: 11)),
                            onSort: _onSort,
                          ),
                      ],
                      rows: [
                        for (final row in rows)
                          DataRow(
                            cells: [
                              for (var i = 0; i < data.columns.length; i++)
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
  }
}
