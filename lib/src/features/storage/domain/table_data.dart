import 'package:flutter/foundation.dart';

/// A readable snapshot of one database table: column names plus rows, each row
/// a list of pre-stringified cells aligned to [columns].
@immutable
class DebugLensTableData {
  /// Column names, in display order.
  final List<String> columns;

  /// The rows, each a list of pre-stringified cells aligned to [columns].
  final List<List<String>> rows;

  /// Builds a snapshot of one table. Cells are stringified by the caller, so
  /// DebugLens keeps no reference to the app's row objects.
  const DebugLensTableData({required this.columns, required this.rows});

  /// A table with no columns and no rows — what to return for a table that is
  /// empty or could not be read.
  static const DebugLensTableData empty = DebugLensTableData(
    columns: [],
    rows: [],
  );
}
