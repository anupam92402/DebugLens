import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/app.dart';
import 'src/core/di/service_locator.dart';
import 'src/core/firebase/mock_firebase.dart';
import 'src/core/logging/app_log.dart';
import 'src/core/notifications/notification_service.dart';
import 'src/core/storage/storage_setup.dart';

void main() => _bootstrap();

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Route Flutter's two error channels into the Logs feed. DebugLens doesn't
  /// install these itself — the app stays in charge of its own error handling,
  /// and both are the current Flutter way (no zone wrapping needed).
  FlutterError.onError = (details) {
    log.e(
      details.exceptionAsString(),
      name: 'flutter',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    log.e('Uncaught error', name: 'app', error: error, stackTrace: stack);
    return false;
  };

  /// Console echo is the host's call — DebugLens no longer assumes. This app
  /// wants it in debug builds only.
  DebugLensLogger.instance.printToConsole = kDebugMode;

  final startup = Stopwatch()..start();

  /// Time the whole startup as a mock-Firebase performance trace.
  final startTrace = MockFirebase.performance.newTrace('app_start')..start();

  /// Feed every cubit/bloc in the app into the DebugLens Bloc inspector.
  Bloc.observer = DebugLensBlocObserver();
  setupLocator();

  /// Mock Firebase init: seed realistic data + identify the user.
  MockFirebase.configure();

  /// Real app storage (SharedPreferences + Drift), bridged to DebugLens.
  await setupStorage();

  /// Fetch + activate Remote Config (applies any persisted device overrides).
  await MockFirebase.activate();
  log.d('Remote Config activated', name: 'config');

  /// Local notifications — request permission up front.
  try {
    await sl<NotificationService>().init();
  } catch (error, stack) {
    log.e(
      'Notification setup failed',
      name: 'notifications',
      error: error,
      stackTrace: stack,
    );
  }

  startTrace.stop();
  startup.stop();
  MockFirebase.analytics.logEvent(
    'app_open',
    action: 'launch',
    category: 'lifecycle',
  );
  log.i('Startup finished in ${startup.elapsedMilliseconds}ms', name: 'app');

  runApp(const ExampleApp());
}
