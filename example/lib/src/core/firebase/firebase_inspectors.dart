import 'dart:convert';

import 'package:debug_lens/debug_lens.dart';

import 'mock_firebase.dart';
import 'mock_remote_config.dart';

/// Registers all four mock Firebase services with the DebugLens Firebase
/// inspector. Idempotent (DebugLens dedupes by name), so it is safe to call
/// from `setupLocator`.
void registerFirebaseInspectors() {
  DebugLens.registerFirebaseService(_AnalyticsInspector());
  DebugLens.registerFirebaseService(_PerformanceInspector());
  DebugLens.registerFirebaseService(_CrashlyticsInspector());
  DebugLens.registerFirebaseService(_RemoteConfigInspector());
}

String _hms(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}

class _AnalyticsInspector extends DebugLensFirebaseService {
  @override
  String get name => 'Analytics';

  @override
  Future<List<DebugLensInfoGroup>> load() async {
    final a = MockFirebase.analytics;
    return [
      DebugLensInfoGroup(
        title: 'Summary',
        values: {
          'Events logged': '${a.events.length}',
          'User id': a.userId ?? '—',
        },
      ),
      if (a.userProperties.isNotEmpty)
        DebugLensInfoGroup(title: 'User properties', values: a.userProperties),
      DebugLensInfoGroup(
        title: 'Recent events',
        values: {
          for (var i = 0; i < a.events.length && i < 20; i++)
            '#${i + 1} ${a.events[i].name}':
                '${_hms(a.events[i].time)}'
                '${a.events[i].parameters.isEmpty ? '' : ' · ${jsonEncode(a.events[i].parameters)}'}',
        },
      ),
    ];
  }
}

class _PerformanceInspector extends DebugLensFirebaseService {
  @override
  String get name => 'Performance';

  @override
  Future<List<DebugLensInfoGroup>> load() async {
    final traces = MockFirebase.performance.traces;
    final slowest = traces.isEmpty
        ? null
        : traces.reduce((a, b) => a.duration >= b.duration ? a : b);
    return [
      DebugLensInfoGroup(
        title: 'Summary',
        values: {
          'Traces': '${traces.length}',
          'Slowest': slowest == null
              ? '—'
              : '${slowest.name} (${slowest.duration.inMilliseconds} ms)',
        },
      ),
      DebugLensInfoGroup(
        title: 'Recent traces',
        values: {
          for (var i = 0; i < traces.length && i < 20; i++)
            '#${i + 1} ${traces[i].name}':
                '${traces[i].duration.inMilliseconds} ms · ${_hms(traces[i].time)}'
                '${traces[i].attributes.isEmpty ? '' : ' · ${jsonEncode(traces[i].attributes)}'}',
        },
      ),
    ];
  }
}

class _CrashlyticsInspector extends DebugLensFirebaseService {
  @override
  String get name => 'Crashlytics';

  @override
  Future<List<DebugLensInfoGroup>> load() async {
    final c = MockFirebase.crashlytics;
    final fatal = c.reports.where((r) => r.fatal).length;
    return [
      DebugLensInfoGroup(
        title: 'Summary',
        values: {
          'Non-fatal': '${c.reports.length - fatal}',
          'Fatal': '$fatal',
          'User': c.userIdentifier ?? '—',
        },
        sensitiveKeys: const {'User'},
      ),
      if (c.customKeys.isNotEmpty)
        DebugLensInfoGroup(title: 'Custom keys', values: c.customKeys),
      DebugLensInfoGroup(
        title: 'Recent errors',
        values: {
          for (var i = 0; i < c.reports.length && i < 15; i++)
            '#${i + 1} ${c.reports[i].fatal ? '[fatal] ' : ''}${_hms(c.reports[i].time)}':
                c.reports[i].message,
        },
      ),
      DebugLensInfoGroup(
        title: 'Breadcrumbs',
        values: {
          for (var i = 0; i < c.breadcrumbs.length && i < 20; i++)
            '#${i + 1}': c.breadcrumbs[i],
        },
      ),
    ];
  }
}

class _RemoteConfigInspector extends DebugLensFirebaseService {
  @override
  String get name => 'Remote Config';

  @override
  Future<List<DebugLensInfoGroup>> load() async {
    final rc = MockFirebase.remoteConfig;
    final active = rc.all;
    return [
      DebugLensInfoGroup(
        title: 'Fetch status',
        values: {
          'Status': rc.lastFetchStatus,
          'Last fetch': rc.lastFetchTime == null
              ? '—'
              : _hms(rc.lastFetchTime!),
          'Parameters': '${active.length}',
        },
      ),
      DebugLensInfoGroup(
        title: 'Parameters',
        values: {
          for (final e in active.entries)
            e.key:
                '${e.value}  '
                '(${rc.sourceOf(e.key) == RemoteConfigValueSource.remote ? 'remote' : 'default'})',
        },
      ),
    ];
  }
}
