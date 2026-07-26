import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/foundation.dart';

import 'mock_firebase.dart';

/// Registers the two read-only mock Firebase services with the DebugLens
/// Services inspector. Idempotent (DebugLens dedupes by name), so it is safe to
/// call from `setupLocator`.
///
/// Only the *pull-based* services are here. The two push-based ones register
/// themselves from their own wrappers: Remote Config from
/// `MockRemoteConfig.initialize` via `DebugLens.instance.setRemoteConfigData`,
/// and Crashlytics from `MockCrashlytics.initialize` via
/// `DebugLens.instance.initCrashReporting`.
///
/// Firebase is just this app's choice — `DebugLensService` is vendor-neutral.
void registerFirebaseInspectors() {
  DebugLens.registerService(_AnalyticsInspector());
  DebugLens.registerService(_PerformanceInspector());
}

String _hms(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}

/// Analytics — one record per logged event (name + fields + timestamp).
class _AnalyticsInspector extends DebugLensService {
  @override
  String get name => 'Analytics';

  @override
  bool get canClear => true;

  /// Live-updates the open inspector as the app logs events.
  @override
  Listenable get changes => MockFirebase.analytics.revision;

  @override
  Future<void> clear() async => MockFirebase.analytics.clear();

  @override
  Future<List<DebugLensServiceGroup>> load() async {
    return [
      for (final e in MockFirebase.analytics.events)
        DebugLensServiceGroup(
          title: e.name,
          subtitle: _hms(e.time),
          values: {
            if (e.action != null) 'action': e.action!,
            if (e.screenName != null) 'screen': e.screenName!,
            if (e.category != null) 'category': e.category!,
          },
        ),
    ];
  }
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
