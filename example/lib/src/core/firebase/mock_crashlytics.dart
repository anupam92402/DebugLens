import 'package:debug_lens/debug_lens.dart';

/// In-memory stand-in for `FirebaseCrashlytics`.
///
/// Write-only and stateless, like the real thing: each recorded error is pushed
/// straight into DebugLens, which owns the list the inspector renders — so this
/// app implements no `load()` for it at all.
///
/// A real wrapper looks the same, with one extra line in [recordError]:
/// `FirebaseCrashlytics.instance.recordError(...)` alongside the DebugLens push.
class MockCrashlytics {
  MockCrashlytics._();

  static final MockCrashlytics instance = MockCrashlytics._();

  /// Puts the crash service on the DebugLens Services screen up front, so it
  /// reads as "nothing has failed yet" instead of being absent until the first
  /// error. Mirrors a real wrapper's `initialize()`.
  void initialize() => DebugLens.instance.initCrashReporting();

  /// Records a caught error. [fatal] marks an unrecoverable crash; the default
  /// is a non-fatal (the common "log and continue" case).
  void recordError({
    required Object error,
    StackTrace? stackTrace,
    bool fatal = false,
    String? reason,
    Map<String, Object?>? customData,
    Iterable<Object> information = const [],
  }) {
    DebugLens.instance.recordCrash(
      DebugLensCrashEvent(
        error: error,
        stackTrace: stackTrace,
        fatal: fatal,
        reason: reason,
        customData: customData ?? const {},
        information: information,
      ),
    );
  }
}
