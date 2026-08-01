import 'dart:ui' show Rect;

import '../../../core/debug_log_file_service.dart';
import '../../../shared/debug_strings.dart';
import '../domain/config_editor.dart';
import '../domain/service_group.dart';

/// Serializes what a service screen is currently showing and shares it as a log
/// file. Handles both read-only services (groups) and editable ones (config
/// entries).
class ServiceLogShare {
  ServiceLogShare._();

  static Future<void> shareGroups(
    String serviceName,
    List<DebugLensServiceGroup> groups, {
    Rect? origin,
  }) => _share(serviceName, _dumpGroups(groups), origin: origin);

  /// [groups] are any read-only blocks the editable service also exposes (fetch
  /// status, …); they precede the parameters in the export.
  static Future<void> shareEntries(
    String serviceName,
    List<DebugLensConfigEntry> entries, {
    List<DebugLensServiceGroup> groups = const [],
    Rect? origin,
  }) => _share(
    serviceName,
    groups.isEmpty
        ? _dumpEntries(entries)
        : '${_dumpGroups(groups)}\n\n${_dumpEntries(entries)}',
    origin: origin,
  );

  static Future<void> _share(
    String serviceName,
    String text, {
    Rect? origin,
  }) async {
    DebugLogFileService.instance.setSection('services/$serviceName', text);
    await DebugLogFileService.instance.shareLogFile(
      name: 'service_logs',
      subject: DebugStrings.serviceShareSubject(serviceName),
      sharePositionOrigin: origin,
    );
  }

  static String _dumpGroups(List<DebugLensServiceGroup> groups) {
    final b = StringBuffer()..writeln('${groups.length} records');
    for (final g in groups) {
      b
        ..writeln()
        ..writeln(g.subtitle == null ? g.title : '${g.title}  (${g.subtitle})');
      for (final e in g.values.entries) {
        b.writeln('  ${e.key}: ${e.value}');
      }
    }
    return b.toString().trimRight();
  }

  static String _dumpEntries(List<DebugLensConfigEntry> entries) {
    final b = StringBuffer()..writeln('${entries.length} parameters');
    for (final e in entries) {
      b.writeln(
        '${e.key} (${e.type.name}) = ${e.value}'
        '${e.overridden ? '  [custom]' : ''}',
      );
    }
    return b.toString().trimRight();
  }
}
