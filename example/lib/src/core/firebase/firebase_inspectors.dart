import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/foundation.dart';

import 'mock_firebase.dart';

/// Registers the one read-only mock Firebase service with the DebugLens
/// Services inspector. Idempotent (DebugLens dedupes by name), so it is safe to
/// call from `setupLocator`.
///
/// Only the *pull-based* service is here — Performance, whose traces this app
/// keeps itself. The push-based ones register from their own wrappers'
/// `initialize()`: Remote Config through `setRemoteConfigData`, Crashlytics
/// through `initCrashReporting`, Analytics through `initAnalytics`.
///
/// Firebase is just this app's choice — `DebugLensService` is vendor-neutral.
void registerFirebaseInspectors() {
  DebugLens.registerService(_PerformanceInspector());
}

String _hms(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}

/// Performance — one record per finished trace (screen load / network call).
class _PerformanceInspector extends DebugLensService {
  @override
  String get name => 'Performance';

  @override
  bool get canClear => true;

  @override
  Listenable get changes => MockFirebase.performance.revision;

  @override
  Future<void> clear() async => MockFirebase.performance.clear();

  @override
  Future<List<DebugLensServiceGroup>> load() async {
    return [
      for (final t in MockFirebase.performance.traces)
        DebugLensServiceGroup(
          title: t.name,
          subtitle: '${t.duration.inMilliseconds} ms · ${_hms(t.time)}',
          values: {
            'duration': '${t.duration.inMilliseconds} ms',
            ...t.attributes,
            for (final m in t.metrics.entries) m.key: '${m.value}',
          },
        ),
    ];
  }
}
