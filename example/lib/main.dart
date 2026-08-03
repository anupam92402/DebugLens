import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/app.dart';
import 'src/core/di/service_locator.dart';
import 'src/core/firebase/mock_firebase.dart';
import 'src/core/notifications/notification_service.dart';
import 'src/core/storage/storage_setup.dart';

void main() => _bootstrap();

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Routes Flutter's error channels into the Logs feed.
  FlutterError.onError = (details) {
    DebugLensLogger().e(
      details.exceptionAsString(),
      name: 'flutter',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    DebugLensLogger().e(
      'Uncaught error',
      name: 'app',
      error: error,
      stackTrace: stack,
    );
    return false;
  };

  // Swaps Flutter's red error box for DebugLens's shareable one.
  ErrorWidget.builder = (details) => CustomErrorScreen(details: details);

  // Master switch — on in every mode here so a release build stays inspectable.
  DebugLens.debugLensEnabled = true;

  // Opens straight into the full panel instead of the default tester role.
  DebugLens.initialRole = DebugRole.developer;

  // What a tester sees on a fresh install; editable later from Settings.
  DebugLens.initialTesterAccess = {
    DebugScreen.network,
    DebugScreen.logs,
    DebugScreen.device,
  };

  // Echo to console only in debug builds.
  DebugLensLogger().printToConsole = kDebugMode;

  final startup = Stopwatch()..start();

  // Time the whole startup as a mock-Firebase performance trace.
  await MockFirebase.performance.trace('app_start', () async {
    // Feed every cubit/bloc in the app into the DebugLens Bloc inspector.
    Bloc.observer = DebugLensBlocObserver();
    setupLocator();

    // Mock Firebase init: seed realistic data + identify the user.
    MockFirebase.configure();

    // Hands the app's real version to DebugLens; an override applies next start.
    await DebugLens.instance.setAppVersion('1.0.0+1');

    // Real app storage (SharedPreferences + Drift), bridged to DebugLens.
    await setupStorage();

    // Fetch + activate Remote Config (applies any persisted device overrides).
    await MockFirebase.activate();
    DebugLensLogger().d('Remote Config activated', name: 'config');

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
  });

  startup.stop();
  MockFirebase.analytics.logEvent(
    'app_open',
    parameters: {
      'action': 'launch',
      'category': 'lifecycle',
      'startup_ms': startup.elapsedMilliseconds,
    },
  );
  DebugLensLogger().i(
    'Startup finished in ${startup.elapsedMilliseconds}ms',
    name: 'app',
  );

  runApp(const ExampleApp());
}
