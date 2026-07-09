import 'package:flutter/foundation.dart';

/// A readable snapshot of one database table: column names plus rows, each row
/// a list of pre-stringified cells aligned to [columns].
@immutable
class DebugLensTableData {
  final List<String> columns;
  final List<List<String>> rows;

  const DebugLensTableData({required this.columns, required this.rows});

  static const DebugLensTableData empty = DebugLensTableData(
    columns: [],
    rows: [],
  );

  int get rowCount => rows.length;
}
