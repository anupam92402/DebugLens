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

  /// One-time setup mirroring app-level Firebase init: stages the remote-config
  /// server values a fetch will activate and identifies the user. Idempotent.
  static void configure() {
    if (_configured) return;
    _configured = true;
    remoteConfig.setServerValues(const {
      'home_header_title': 'Your day',
      'promo_banner_text': '🎉 20% off Pro — this week only',
      'home_layout_experiment': 'variant_b',
      'notification_batch_size': 4,
    });
    crashlytics.setUserIdentifier('demo-user-42');
    analytics.setUserId('demo-user-42');
  }

  /// Simulates Firebase startup: fetch + activate remote config inside a perf
  /// trace, leaving a startup breadcrumb and an analytics event.
  static Future<void> activate() async {
    crashlytics.log('App startup');
    await performance.trace(
      'remote_config_fetch',
      remoteConfig.fetchAndActivate,
    );
    analytics.logEvent(
      'remote_config_activated',
      parameters: {'params': remoteConfig.all.length},
    );
  }
}
