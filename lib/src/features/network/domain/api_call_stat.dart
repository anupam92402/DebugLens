import 'network_entry.dart';

/// Session-scoped call stats for one endpoint (method + path), shown on the
/// Network → History screen. Independent of the log — survives clearing it.
class ApiCallStat {
  final HttpMethod method;
  final String path;

  /// Total number of times this endpoint was called this session.
  int total;

  /// Outcome breakdown; the three always sum to [total].
  int success;
  int error;
  int pending;

  /// When this endpoint was last called (request initiation time).
  DateTime lastCalled;

  ApiCallStat({
    required this.method,
    required this.path,
    required this.lastCalled,
    this.total = 0,
    this.success = 0,
    this.error = 0,
    this.pending = 0,
  });

  String get methodLabel => method.name.toUpperCase();

  /// Count for [kind], or [total] when null (the "frequency" / All view).
  int countFor(NetworkStatusKind? kind) {
    switch (kind) {
      case null:
        return total;
      case NetworkStatusKind.success:
        return success;
      case NetworkStatusKind.error:
        return error;
      case NetworkStatusKind.pending:
        return pending;
    }
  }
}
