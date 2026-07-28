import 'package:flutter/foundation.dart';

import '../../../core/debug_lens_config.dart';
import '../../../shared/debug_constants.dart';
import '../../settings/data/debug_limits_store.dart';
import '../../settings/domain/debug_limit.dart';
import '../../../shared/debug_strings.dart';
import '../../../shared/util/clock_format.dart';
import '../domain/service_group.dart';
import '../domain/trace_event.dart';
import 'debug_service_source.dart';

/// DebugLens's own store for pushed performance traces.
///
/// Performance SDKs are write-only — you can't ask Firebase what it timed — so
/// like the crash and analytics stores this one keeps what the host hands over
/// through `DebugLens.instance.recordTrace`. Newest-first, ring-buffered at
/// the Traces limit, which is editable from Settings.
class DebugTraceStore {
  DebugTraceStore._();

  static final DebugTraceStore instance = DebugTraceStore._();

  final List<DebugLensTraceEvent> _events = <DebugLensTraceEvent>[];

  /// Recorded traces, newest-first. Unmodifiable so callers can't mutate the
  /// store behind [record]'s back.
  List<DebugLensTraceEvent> get events => List.unmodifiable(_events);

  /// Bumped on every change — wired to `DebugLensService.changes`, so an open
  /// service screen re-pulls as traces finish behind it.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void record(DebugLensTraceEvent event) {
    if (!DebugLensConfig.enabled) return;
    _events.insert(0, event);
    if (_events.length > DebugLimits.instance.of(DebugLimit.traces)) {
      _events.removeLast();
    }
    revision.value++;
  }

  void clear() {
    _events.clear();
    revision.value++;
  }
}

/// The Services-screen entry DebugLens registers for pushed traces.
class DebugTraceService extends DebugLensService {
  DebugTraceService({required this.name});

  @override
  final String name;

  @override
  bool get canClear => true;

  @override
  Listenable get changes => DebugTraceStore.instance.revision;

  @override
  Future<void> clear() async => DebugTraceStore.instance.clear();

  @override
  Future<List<DebugLensServiceGroup>> load() async => [
    for (final event in DebugTraceStore.instance.events) _groupFor(event),
  ];

  /// One record per trace: the name as the title, duration and time as the
  /// second line, and the attributes as the fields shown when the row expands.
  /// The duration isn't repeated as a field — it is already on the row.
  static DebugLensServiceGroup _groupFor(DebugLensTraceEvent event) {
    return DebugLensServiceGroup(
      title: event.name,
      subtitle:
          '${DebugStrings.traceDuration(event.duration.inMilliseconds)}'
          ' · ${ClockFormat.clock(event.time)}',
      values: {
        for (final entry in event.attributes.entries)
          entry.key: entry.value?.toString() ?? DebugConstants.emptyValue,
      },
    );
  }
}
