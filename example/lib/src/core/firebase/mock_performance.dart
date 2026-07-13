import 'package:flutter/foundation.dart';

/// A finished performance trace, mirroring a stopped `Trace`.
@immutable
class MockTraceRecord {
  final String name;
  final Duration duration;
  final Map<String, int> metrics;
  final Map<String, String> attributes;
  final DateTime time;

  const MockTraceRecord({
    required this.name,
    required this.duration,
    required this.metrics,
    required this.attributes,
    required this.time,
  });
}

/// A single in-flight trace, mirroring `FirebasePerformance`'s `Trace`. Call
/// [start], optionally add metrics/attributes, then [stop] to record it.
class MockTrace {
  MockTrace(this._owner, this.name);

  final MockPerformance _owner;
  final String name;
  final Map<String, int> _metrics = {};
  final Map<String, String> _attributes = {};
  Stopwatch? _sw;

  void start() => _sw = Stopwatch()..start();

  void setMetric(String key, int value) => _metrics[key] = value;

  void putAttribute(String key, String value) => _attributes[key] = value;

  void stop() {
    _sw?.stop();
    _owner._record(
      MockTraceRecord(
        name: name,
        duration: _sw?.elapsed ?? Duration.zero,
        metrics: Map.of(_metrics),
        attributes: Map.of(_attributes),
        time: DateTime.now(),
      ),
    );
  }
}

/// In-memory stand-in for `FirebasePerformance`. Records finished traces (page
/// loads, network calls, startup) for the DebugLens Firebase inspector.
class MockPerformance {
  MockPerformance._();
  static final MockPerformance instance = MockPerformance._();

  static const int _maxTraces = 100;

  /// Newest-first, ring-buffered to the latest [_maxTraces].
  final List<MockTraceRecord> traces = [];

  MockTrace newTrace(String name) => MockTrace(this, name);

  /// Times [action] under a trace of [name] and records it — the common
  /// "wrap this async work" case (page load, network request).
  Future<T> trace<T>(String name, Future<T> Function() action) async {
    final t = newTrace(name)..start();
    try {
      return await action();
    } finally {
      t.stop();
    }
  }

  void _record(MockTraceRecord record) {
    traces.insert(0, record);
    if (traces.length > _maxTraces) traces.removeLast();
  }
}
