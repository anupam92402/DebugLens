import 'package:flutter/foundation.dart';

import '../../../core/debug_lens_config.dart';
import '../../../shared/debug_constants.dart';
import '../../settings/data/debug_limits_store.dart';
import '../../settings/domain/debug_limit.dart';
import '../../../shared/debug_strings.dart';
import '../../../shared/util/clock_format.dart';
import '../domain/crash_event.dart';
import '../domain/service_group.dart';
import 'debug_service_source.dart';

/// DebugLens's own store for pushed crash reports.
class DebugCrashStore {
  DebugCrashStore._();

  static final DebugCrashStore instance = DebugCrashStore._();

  final List<DebugLensCrashEvent> _events = <DebugLensCrashEvent>[];

  /// Recorded events, newest-first. Unmodifiable so callers can't mutate the
  /// store behind [record]'s back.
  List<DebugLensCrashEvent> get events => List.unmodifiable(_events);

  /// Bumped on every change — wired to `DebugLensService.changes`, so an open
  /// service screen re-pulls as errors are recorded behind it.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void record(DebugLensCrashEvent event) {
    if (!DebugLensConfig.enabled) return;
    _events.insert(0, event);
    if (_events.length > DebugLimits.instance.of(DebugLimit.crashes)) {
      _events.removeLast();
    }
    revision.value++;
  }

  void clear() {
    _events.clear();
    revision.value++;
  }
}

/// The Services-screen entry DebugLens registers for pushed crash reports, so
/// they appear alongside the host's own pull-based services.
class DebugCrashService extends DebugLensService {
  DebugCrashService({required this.name});

  @override
  final String name;

  @override
  bool get canClear => true;

  @override
  Listenable get changes => DebugCrashStore.instance.revision;

  @override
  Future<void> clear() async => DebugCrashStore.instance.clear();

  @override
  Future<List<DebugLensServiceGroup>> load() async => [
    for (final event in DebugCrashStore.instance.events) _groupFor(event),
  ];

  /// One record per report: the error as the title, severity + time as the
  /// subtitle, and the details as fields.
  static DebugLensServiceGroup _groupFor(DebugLensCrashEvent event) {
    final values = <String, String>{
      DebugStrings.crashErrorLabel: '${event.error}',
      if (event.reason != null) DebugStrings.crashReasonLabel: event.reason!,
    };

    /// Custom keys are host-named, so they can collide with the fields above.
    for (final entry in event.customData.entries) {
      values.putIfAbsent(
        entry.key,
        () => entry.value?.toString() ?? DebugConstants.emptyValue,
      );
    }
    if (event.information.isNotEmpty) {
      values[DebugStrings.crashInfoLabel] = event.information.join('\n');
    }
    if (event.stackTrace != null) {
      values[DebugStrings.crashStackLabel] = '${event.stackTrace}';
    }

    return DebugLensServiceGroup(
      title: '${event.error}',
      subtitle:
          '${event.fatal ? DebugStrings.crashFatal : DebugStrings.crashNonFatal}'
          ' · ${ClockFormat.clock(event.time)}',
      values: values,
    );
  }
}
