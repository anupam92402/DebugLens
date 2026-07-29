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

  /// Route Flutter's two error channels into the Logs feed. DebugLens doesn't
  /// install these itself — the app stays in charge of its own error handling,
  /// and both are the current Flutter way (no zone wrapping needed).
  FlutterError.onError = (details) {
    debugLog.e(
      details.exceptionAsString(),
      name: 'flutter',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugLog.e('Uncaught error', name: 'app', error: error, stackTrace: stack);
    return false;
  };

  /// Swap Flutter's red error box for DebugLens's readable, shareable one.
  /// Also the host's call — DebugLens supplies the widget and the Settings
  /// switch that decides whether it renders, but never installs the builder.
  ErrorWidget.builder = (details) => CustomErrorScreen(details: details);

  /// The one switch that decides whether DebugLens runs at all. This demo keeps
  /// it on in every mode so a release build can be inspected too; a real app
  /// would usually write `!kReleaseMode` or gate it on a flavor.
  DebugLens.debugLensEnabled = true;

  /// This demo opens straight into the full panel. A real app might leave the
  /// default (tester) so a QA build only exposes what it has been granted.
  DebugLens.initialRole = DebugRole.developer;

  /// What a tester gets on a fresh install, without anyone ticking boxes on the
  /// device. Editable later from Settings, and the edited set then wins.
  DebugLens.initialTesterAccess = {
    DebugScreen.network,
    DebugScreen.logs,
    DebugScreen.device,
  };

  /// Console echo is the host's call — DebugLens no longer assumes. This app
  /// wants it in debug builds only.
  DebugLensLogger.instance.printToConsole = kDebugMode;

  final startup = Stopwatch()..start();

  /// Time the whole startup as a mock-Firebase performance trace.
  await MockFirebase.performance.trace('app_start', () async {
    /// Feed every cubit/bloc in the app into the DebugLens Bloc inspector.
    Bloc.observer = DebugLensBlocObserver();
    setupLocator();

    /// Mock Firebase init: seed realistic data + identify the user.
    MockFirebase.configure();

    /// Hand the app's real version (from pubspec) to DebugLens, and read it
    /// back through `DebugLens.instance.appVersion` wherever the app shows it —
    /// so an override set in the panel takes effect on the next start.
    await DebugLens.instance.setAppVersion('1.0.0+1');

    /// Real app storage (SharedPreferences + Drift), bridged to DebugLens.
    await setupStorage();

    /// Fetch + activate Remote Config (applies any persisted device overrides).
    await MockFirebase.activate();
    debugLog.d('Remote Config activated', name: 'config');

    /// Local notifications — request permission up front.
    try {
      await sl<NotificationService>().init();
    } catch (error, stack) {
      debugLog.e(
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
  debugLog.i(
    'Startup finished in ${startup.elapsedMilliseconds}ms',
    name: 'app',
  );

  runApp(const ExampleApp());
}
