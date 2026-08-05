import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/foundation.dart';

/// Routes Flutter's two error channels into the Logs feed. DebugLens doesn't
/// install these itself — the app stays in charge of its own error handling,
/// and both are the current Flutter way (no zone wrapping needed).
void logErrorRouting() {
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
}
