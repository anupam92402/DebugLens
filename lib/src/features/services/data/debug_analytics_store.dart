import 'package:flutter/foundation.dart';

import '../../../core/debug_lens_config.dart';
import '../../../shared/debug_constants.dart';
import '../../settings/data/debug_limits_store.dart';
import '../../settings/domain/debug_limit.dart';
import '../../../shared/util/clock_format.dart';
import '../domain/analytics_event.dart';
import '../domain/service_group.dart';
import 'debug_service_source.dart';

/// DebugLens's own store for pushed analytics events.
///
/// Analytics SDKs are write-only — you can't ask Firebase what you logged — so
/// like the crash store this one keeps what the host hands over through
/// `DebugLens.instance.recordAnalyticsEvent`. Newest-first, ring-buffered at
/// the Analytics limit, which is editable from Settings.
class DebugAnalyticsStore {
  DebugAnalyticsStore._();

  static final DebugAnalyticsStore instance = DebugAnalyticsStore._();

  final List<DebugLensAnalyticsEvent> _events = <DebugLensAnalyticsEvent>[];

  /// Recorded events, newest-first. Unmodifiable so callers can't mutate the
  /// store behind [record]'s back.
  List<DebugLensAnalyticsEvent> get events => List.unmodifiable(_events);

  /// Bumped on every change — wired to `DebugLensService.changes`, so an open
  /// service screen re-pulls as events are logged behind it.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void record(DebugLensAnalyticsEvent event) {
    if (!DebugLensConfig.enabled) return;
    _events.insert(0, event);
    if (_events.length > DebugLimits.instance.of(DebugLimit.analytics)) {
      _events.removeLast();
    }
    revision.value++;
  }

  void clear() {
    _events.clear();
    revision.value++;
  }
}

/// The Services-screen entry DebugLens registers for pushed analytics events.
class DebugAnalyticsService extends DebugLensService {
  DebugAnalyticsService({required this.name});

  @override
  final String name;

  @override
  bool get canClear => true;

  @override
  Listenable get changes => DebugAnalyticsStore.instance.revision;

  @override
  Future<void> clear() async => DebugAnalyticsStore.instance.clear();

  @override
  Future<List<DebugLensServiceGroup>> load() async => [
    for (final event in DebugAnalyticsStore.instance.events) _groupFor(event),
  ];

  /// One record per event: the name as the title, the time as the second line
  /// under it, and the parameters as the fields shown when the row expands.
  static DebugLensServiceGroup _groupFor(DebugLensAnalyticsEvent event) {
    return DebugLensServiceGroup(
      title: event.name,
      subtitle: ClockFormat.clock(event.time),
      values: {
        for (final entry in event.parameters.entries)
          entry.key: entry.value?.toString() ?? DebugConstants.emptyValue,
      },
    );
  }
}
