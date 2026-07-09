import 'network_entry.dart';

/// Aggregated call stats for a single API endpoint (method + path), shown on
/// the Network → History screen.
///
/// Counts are kept in memory for the lifetime of the app session and are
/// independent of the Network log: clearing the log does not reset history,
/// and the data is only gone when the app is killed and relaunched.
class ApiCallStat {
  final HttpMethod method;
  final String path;

  /// Total number of times this endpoint was called this session.
  int total;

  /// Outcome breakdown. As pending calls complete they move from [pending]
  /// into [success] or [error]; the three always sum to [total].
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

  /// Count for a given status [kind], or [total] when [kind] is null
  /// (the "frequency" / All view).
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
