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

  /// Cap on retained per-call timestamps. [total] keeps counting past this, so
  /// a long session stays bounded while the aggregate stays exact.
  static const int maxCallTimes = 100;

  final List<DateTime> _callTimes = <DateTime>[];

  /// Request time of each retained call, oldest first — the calls sheet reads
  /// this and derives the gap between consecutive calls.
  List<DateTime> get callTimes => List.unmodifiable(_callTimes);

  /// Whether older calls were dropped, so the sheet can say so.
  bool get isTrimmed => total > _callTimes.length;

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

  /// Registers one call at [at]. Bumps [total], moves [lastCalled] and keeps
  /// the timestamp — grouped so the three can't drift apart.
  void recordCall(DateTime at) {
    total += 1;
    lastCalled = at;
    _callTimes.add(at);
    if (_callTimes.length > maxCallTimes) _callTimes.removeAt(0);
  }

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
