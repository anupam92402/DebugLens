import 'dart:io';
import 'dart:ui' show Rect;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Centralised creator + sharer of DebugLens log files.
///
/// Any feature/service (navigation, bloc, firebase, …) contributes data under
/// a named source — either by pushing over time with [log] / [setSection], or
/// by passing sections inline to [shareLogFile]. Calling [shareLogFile] writes
/// a brand-new file and opens the OS share sheet; that is the only supported
/// way to share a log file. Sharing goes through `share_plus`, so it works on
/// both Android and iOS.
///
/// The dump is segregated per source with a `/// <source>` header so it stays
/// readable:
/// ```
/// /// navigation
/// <navigation data>
///
/// /// bloc
/// <bloc data>
/// ```
///
/// Nothing here is wired into the DebugLens screens — it is a standalone
/// service a caller drives explicitly, e.g.:
/// ```dart
/// DebugLogFileService.instance
///   ..log('navigation', 'push /home')
///   ..log('bloc', 'AuthBloc: LoggedIn');
/// await DebugLogFileService.instance.shareLogFile(subject: 'DebugLens logs');
/// ```
class DebugLogFileService {
  DebugLogFileService._();

  /// Shared instance.
  static final DebugLogFileService instance = DebugLogFileService._();

  /// Insertion-ordered buffer of `source -> content`. First-seen order is the
  /// order sources appear in the dump.
  final Map<String, StringBuffer> _sections = <String, StringBuffer>{};

  /// Appends one [message] line under [source] (created on first use).
  void log(String source, String message) {
    (_sections[source] ??= StringBuffer()).writeln(message);
  }

  /// Appends several [lines] under [source] in order.
  void logLines(String source, Iterable<String> lines) {
    final buffer = _sections[source] ??= StringBuffer();
    for (final line in lines) {
      buffer.writeln(line);
    }
  }

  /// Replaces [source]'s whole content in one shot.
  void setSection(String source, String content) {
    _sections[source] = StringBuffer(content);
  }

  /// Drops one source's buffered data.
  void clearSource(String source) => _sections.remove(source);

  /// Drops all buffered data.
  void clear() => _sections.clear();

  /// Immutable snapshot of the current buffer (`source -> content`).
  Map<String, String> snapshot() => <String, String>{
    for (final entry in _sections.entries) entry.key: entry.value.toString(),
  };

  /// Composes the readable, segregated dump. Uses [sections] when provided,
  /// otherwise the accumulated buffer. Each source gets a `/// <source>`
  /// header followed by its data, blank-line separated.
  String buildDump([Map<String, String>? sections]) {
    final data = sections ?? snapshot();
    final out = StringBuffer();
    var first = true;
    for (final entry in data.entries) {
      if (!first) out.writeln();
      first = false;
      out.writeln('/// ${entry.key}');
      final body = entry.value.trimRight();
      if (body.isNotEmpty) out.writeln(body);
    }
    return out.toString();
  }

  static String _pad2(int value) => value.toString().padLeft(2, '0');

  /// Default base used when a caller doesn't pass a [fileNameFor] `name`.
  static const String _defaultName = 'logs';

  /// Filename for [at] (defaults to now, local time), formatted as
  /// `<name>_YYYY-MM-DD_HH-mm-ss.txt` — sorts chronologically in a file list.
  /// [name] defaults to `logs` (e.g. `logs_2026-07-11_14-30-05.txt`); callers
  /// sharing a single feature pass their own, e.g. `navigation_logs`.
  static String fileNameFor({DateTime? at, String? name}) {
    final t = at ?? DateTime.now();
    return '${name ?? _defaultName}_${t.year}-${_pad2(t.month)}-${_pad2(t.day)}_'
        '${_pad2(t.hour)}-${_pad2(t.minute)}-${_pad2(t.second)}.txt';
  }

  /// Writes [buildDump] to a NEW file under the temp directory and returns it.
  /// Every call creates a fresh file; a same-second name collision gets a
  /// numeric suffix. [name] overrides the filename base (see [fileNameFor]).
  Future<File> writeLogFile({
    Map<String, String>? sections,
    String? name,
  }) async {
    final temp = await getTemporaryDirectory();
    final dir = Directory('${temp.path}/debug_lens_logs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    var path = '${dir.path}/${fileNameFor(name: name)}';
    if (await File(path).exists()) {
      path = await _uniquePath(path);
    }
    final file = File(path);
    await file.writeAsString(buildDump(sections), flush: true);
    return file;
  }

  Future<String> _uniquePath(String base) async {
    final stem = base.substring(0, base.length - 4); // strip trailing ".txt"
    var i = 1;
    while (await File('$stem($i).txt').exists()) {
      i++;
    }
    return '$stem($i).txt';
  }

  /// Writes a new log file (see [writeLogFile]) and opens the OS share sheet
  /// via `share_plus` — the only supported way to share a log file.
  ///
  /// Works on Android and iOS. On iPad the share sheet is a popover, so pass
  /// [sharePositionOrigin] (the share control's global rect) to anchor it;
  /// omit on phones. [name] overrides the filename base (see [fileNameFor]).
  Future<ShareResult> shareLogFile({
    Map<String, String>? sections,
    String? name,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    final file = await writeLogFile(sections: sections, name: name);
    return SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile(
            file.path,
            mimeType: 'text/plain',
            name: file.uri.pathSegments.last,
          ),
        ],
        subject: subject,
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
