enum PrefType { boolean, integer, double, string, stringList }

class PrefEntry {
  final String key;
  final Object? value;
  final PrefType type;
  final bool sensitive;

  const PrefEntry({
    required this.key,
    required this.value,
    required this.type,
    this.sensitive = false,
  });

  String get typeLabel {
    switch (type) {
      case PrefType.boolean:
        return 'bool';
      case PrefType.integer:
        return 'int';
      case PrefType.double:
        return 'double';
      case PrefType.string:
        return 'String';
      case PrefType.stringList:
        return 'List<String>';
    }
  }
}

class DbColumn {
  final String name;
  final String type;
  const DbColumn(this.name, this.type);
}

class DbTable {
  final String name;
  final List<DbColumn> columns;
  final List<Map<String, Object?>> rows;

  const DbTable({
    required this.name,
    required this.columns,
    required this.rows,
  });

  int get rowCount => rows.length;
}
