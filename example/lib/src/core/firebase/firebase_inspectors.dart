import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/foundation.dart';

import 'mock_firebase.dart';

/// Registers all four mock Firebase services with the DebugLens Services
/// inspector. Idempotent (DebugLens dedupes by name), so it is safe to call
/// from `setupLocator`.
///
/// Firebase is just this app's choice — `DebugLensService` is vendor-neutral.
void registerFirebaseInspectors() {
  DebugLens.registerService(_AnalyticsInspector());
  DebugLens.registerService(_PerformanceInspector());
  DebugLens.registerService(_CrashlyticsInspector());
  DebugLens.registerService(_RemoteConfigInspector());
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

/// Crashlytics — one record per recorded error, then breadcrumbs. The install
/// id is marked sensitive, so DebugLens masks it until revealed and always
/// redacts it from shared log files.
class _CrashlyticsInspector extends DebugLensService {
  @override
  String get name => 'Crashlytics';

  @override
  bool get canClear => true;

  @override
  Listenable get changes => MockFirebase.crashlytics.revision;

  @override
  Future<void> clear() async => MockFirebase.crashlytics.clear();

  @override
  Future<List<DebugLensServiceGroup>> load() async {
    final c = MockFirebase.crashlytics;
    return [
      DebugLensServiceGroup(
        title: 'Session',
        subtitle: 'installation',
        values: {
          if (c.userIdentifier != null) 'userId': c.userIdentifier!,
          'installId': c.installId,
        },
        sensitiveKeys: const {'installId'},
      ),
      for (final r in c.reports)
        DebugLensServiceGroup(
          title: r.message,
          subtitle: '${r.fatal ? 'fatal' : 'non-fatal'} · ${_hms(r.time)}',
          values: {
            if (r.reason != null) 'reason': r.reason!,
            if (r.stack != null) 'stack': r.stack!,
          },
        ),
      for (final b in c.breadcrumbs)
        DebugLensServiceGroup(
          title: b.message,
          subtitle: 'breadcrumb · ${_hms(b.time)}',
        ),
    ];
  }
}

/// Remote Config — editable, typed key/value store with device overrides. Uses
/// the editor's Reset (not delete) to drop overrides, so [canClear] stays
/// false. [load] returns the fetch status, which renders as a header card above
/// the editable rows.
class _RemoteConfigInspector extends DebugLensService {
  @override
  String get name => 'Remote Config';

  @override
  DebugLensConfigEditor get editor => MockFirebase.remoteConfig;

  @override
  Future<List<DebugLensServiceGroup>> load() async {
    final rc = MockFirebase.remoteConfig;
    return [
      DebugLensServiceGroup(
        title: 'Fetch',
        values: {
          'status': rc.lastFetchStatus,
          'lastFetch': rc.lastFetchTime == null
              ? 'never'
              : _hms(rc.lastFetchTime!),
        },
      ),
    ];
  }
}
