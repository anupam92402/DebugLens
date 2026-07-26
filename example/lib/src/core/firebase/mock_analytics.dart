import 'package:flutter/foundation.dart';

/// One logged analytics event. Mirrors a `FirebaseAnalytics.logEvent` call, but
/// modelled as a small DTO of the fields real events carry: name, action,
/// screen, category and a timestamp.
@immutable
class MockAnalyticsEvent {
  final String name;
  final String? action;
  final String? screenName;
  final String? category;
  final DateTime time;

  const MockAnalyticsEvent({
    required this.name,
    required this.time,
    this.action,
    this.screenName,
    this.category,
  });
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

  /// Bumped whenever [events] changes. Handed to DebugLens as the service's
  /// `changes` signal so an open inspector re-pulls as events arrive.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Logs a custom event with its structured fields.
  void logEvent(
    String name, {
    String? action,
    String? screenName,
    String? category,
  }) {
    events.insert(
      0,
      MockAnalyticsEvent(
        name: name,
        action: action,
        screenName: screenName,
        category: category,
        time: DateTime.now(),
      ),
    );
    if (events.length > _maxEvents) events.removeLast();
    revision.value++;
  }

  /// Convenience for the standard `screen_view` event.
  void logScreenView(String screenName) => logEvent(
    'screen_view',
    action: 'view',
    screenName: screenName,
    category: 'navigation',
  );

  void setUserProperty(String name, String value) =>
      userProperties[name] = value;

  void setUserId(String id) => userId = id;

  void clear() {
    events.clear();
    revision.value++;
  }
}
