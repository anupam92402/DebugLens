import 'package:debug_lens/debug_lens.dart';

import 'di/service_locator.dart';
import 'firebase/mock_firebase.dart';
import 'notifications/notification_service.dart';
import 'storage/storage_setup.dart';

/// Wires up this demo's own fake backend — DI, mock Firebase, real on-device
/// storage, and local notifications. None of this is DebugLens API; it's what
/// the demo needs so the inspectors above have real data to show.
Future<void> initializeDemoBackend() async {
  setupLocator();

  // Mock Firebase init: seed realistic data + identify the user.
  MockFirebase.configure();

  // Real app storage (SharedPreferences + Drift), bridged to DebugLens.
  await setupStorage();

  // Fetch + activate Remote Config (applies any persisted device overrides).
  await MockFirebase.activate();

  // Local notifications — request permission up front.
  try {
    await sl<NotificationService>().init();
  } catch (error, stack) {
    DebugLensLogger().e(
      'Notification setup failed',
      name: 'notifications',
      error: error,
      stackTrace: stack,
    );
  }

  MockFirebase.analytics.logEvent(
    'app_open',
    parameters: {'action': 'launch', 'category': 'lifecycle'},
  );
}
