import 'package:flutter/foundation.dart';

/// One logged analytics event, mirroring a `FirebaseAnalytics.logEvent` call.
@immutable
class MockAnalyticsEvent {
  final String name;
  final Map<String, Object?> parameters;
  final DateTime time;

  const MockAnalyticsEvent(this.name, this.parameters, this.time);
}

/// In-memory stand-in for `FirebaseAnalytics`. Buffers logged events, user
/// properties and the user id so the DebugLens Firebase inspector can render
/// them. Pure Dart — no native/Firebase dependency.
class MockAnalytics {
  MockAnalytics._();
  static final MockAnalytics instance = MockAnalytics._();

  static const int _maxEvents = 100;

  /// Newest-first, ring-buffered to the latest [_maxEvents].
  final List<MockAnalyticsEvent> events = [];
  final Map<String, String> userProperties = {};
  String? userId;

  /// Logs a custom event (e.g. `activity_added`).
  void logEvent(String name, {Map<String, Object?> parameters = const {}}) {
    events.insert(0, MockAnalyticsEvent(name, parameters, DateTime.now()));
    if (events.length > _maxEvents) events.removeLast();
  }

  /// Convenience for the standard `screen_view` event.
  void logScreenView(String screenName) =>
      logEvent('screen_view', parameters: {'screen_name': screenName});

  void setUserProperty(String name, String value) =>
      userProperties[name] = value;

  void setUserId(String id) => userId = id;
}
