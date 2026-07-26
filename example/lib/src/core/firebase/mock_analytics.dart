import 'package:debug_lens/debug_lens.dart';

/// In-memory stand-in for `FirebaseAnalytics`.
///
/// Write-only and stateless, like the real thing: each logged event is pushed
/// straight into DebugLens, which owns the list the inspector renders — so this
/// app implements no `load()` for it at all.
///
/// A real wrapper looks the same, with one extra line in [logEvent]:
/// `FirebaseAnalytics.instance.logEvent(...)` alongside the DebugLens push.
class MockAnalytics {
  MockAnalytics._();

  static final MockAnalytics instance = MockAnalytics._();

  /// Puts the analytics service on the DebugLens Services screen up front, so
  /// it is there from startup instead of appearing with the first event.
  void initialize() => DebugLens.instance.initAnalytics();

  /// Logs a custom event. [name] is the row title; [parameters] carries
  /// everything else and shows up when the row is expanded.
  void logEvent(String name, {Map<String, Object?> parameters = const {}}) =>
      DebugLens.instance.recordAnalyticsEvent(name, parameters: parameters);

  /// Convenience for the standard `screen_view` event. Takes the same map as
  /// [logEvent], merged over the screen name so a caller can add its own
  /// fields.
  void logScreenView(
    String screenName, {
    Map<String, Object?> parameters = const {},
  }) => logEvent(
    'screen_view',
    parameters: {'screen': screenName, ...parameters},
  );
}
