import 'package:debug_lens/debug_lens.dart';

import 'app_database.dart';

/// Bridges the example's [AppDatabase] to DebugLens's read-only
/// [DebugLensDatabase] interface — so debug_lens can show the tables without
/// depending on drift. Generic: works for any table via a raw select.
class DriftDebugLensDatabase implements DebugLensDatabase {
  DriftDebugLensDatabase(this._db);

  final AppDatabase _db;

  @override
  String get name => 'example_app.db';

  @override
  Future<List<String>> tableNames() async =>
      _db.allTables.map((t) => t.actualTableName).toList();

  @override
  Future<DebugLensTableData> tableData(String table) async {
    final rows = await _db.customSelect('SELECT * FROM "$table"').get();
    if (rows.isEmpty) return DebugLensTableData.empty;
    final columns = rows.first.data.keys.toList();
    return DebugLensTableData(
      columns: columns,
      rows: [
        for (final row in rows)
          [for (final c in columns) '${row.data[c] ?? ''}'],
      ],
    );
  }
}
