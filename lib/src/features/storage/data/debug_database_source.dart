import '../domain/table_data.dart';

/// Generic, read-only, async view of one inspectable database, implemented by
/// the host (e.g. a drift/sqflite adapter). DebugLens calls these methods on
/// demand from the Storage screen and keeps no copy of the data — it never
/// imports any client database package.
abstract class DebugLensDatabase {
  /// Display name (e.g. the database file name).
  String get name;

  /// All table names in the database.
  Future<List<String>> tableNames();

  /// All rows of [table], with column metadata.
  Future<DebugLensTableData> tableData(String table);
}

/// Registry of host-provided databases shown in the Storage screen's Database
/// tab. Static + global so the host can register once at startup.
class DebugLensDatabases {
  DebugLensDatabases._();

  /// Registered databases, in insertion order.
  static final List<DebugLensDatabase> sources = [];

  /// Adds [database], replacing any existing one with the same name so repeated
  /// registration (e.g. re-running DI setup) stays idempotent.
  static void register(DebugLensDatabase database) {
    sources.removeWhere((d) => d.name == database.name);
    sources.add(database);
  }
}
