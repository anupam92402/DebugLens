import 'mock_analytics.dart';
import 'mock_crashlytics.dart';
import 'mock_performance.dart';
import 'mock_remote_config.dart';

/// Dedicated mock Firebase facade for the example app. Bundles four in-memory
/// services that behave like their real counterparts (Analytics, Performance,
/// Crashlytics, Remote Config) without pulling in any Firebase dependency, so
/// the app can exercise the DebugLens Firebase inspector with realistic data.
class MockFirebase {
  MockFirebase._();

  static MockAnalytics get analytics => MockAnalytics.instance;
  static MockPerformance get performance => MockPerformance.instance;
  static MockCrashlytics get crashlytics => MockCrashlytics.instance;
  static MockRemoteConfig get remoteConfig => MockRemoteConfig.instance;

  static bool _configured = false;

  /// One-time setup mirroring app-level Firebase init: starts crash reporting
  /// and identifies the user. No seeded data — the services fill up from the
  /// app's real usage (screen views, traces, recorded errors, config reads).
  /// Idempotent.
  static void configure() {
    if (_configured) return;
    _configured = true;
    crashlytics.initialize();
    analytics.setUserId('demo-user-42');
  }

  /// Simulates Firebase startup: fetch + activate Remote Config (applying any
  /// persisted device overrides) inside a perf trace, leaving an analytics
  /// event.
  static Future<void> activate() async {
    await performance.trace('remote_config_fetch', remoteConfig.initialize);
    analytics.logEvent(
      'remote_config_activated',
      action: 'fetch',
      category: 'config',
    );
  }
}
