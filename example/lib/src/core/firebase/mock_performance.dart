import 'package:debug_lens/debug_lens.dart';

/// In-memory stand-in for `FirebasePerformance`.
/// Write-only and stateless, like the real thing: finished traces are pushed
/// straight into DebugLens, which owns the list the inspector renders — so this
/// app implements no `load()` for it at all.
///
/// One way in: [trace] wraps the work it times, so there is no half-started
/// trace to leak and no stop to forget. A real wrapper starts and stops the
/// SDK's own `Trace` in the same two places, and hands its metrics and
/// attributes to `recordTrace` as a map.
class MockPerformance {
  MockPerformance._();

  static final MockPerformance instance = MockPerformance._();

  /// Puts the performance service on the DebugLens Services screen up front, so
  /// it is there from startup instead of appearing with the first trace.
  void initialize() => DebugLens.instance.initPerformance();

  /// Times [action] under a trace of [name] and records it — the common "wrap
  /// this async work" case (startup, page load, network request). Records even
  /// if [action] throws, so a failed operation still shows how long it took.
  Future<T> trace<T>(String name, Future<T> Function() action) async {
    final sw = Stopwatch()..start();
    try {
      return await action();
    } finally {
      sw.stop();
      DebugLens.instance.recordTrace(name, sw.elapsed);
    }
  }
}
