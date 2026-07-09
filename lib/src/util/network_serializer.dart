import 'dart:convert';

import '../core/models/network_entry.dart';
import '../integration/http_status_codes.dart';

/// Plain-text serializers for [NetworkEntry] used by:
/// - the AppBar Copy / Share buttons on the detail screen,
/// - the Share button on the list screen,
/// - the per-row Copy icon (cURL + response export).
///
/// Centralised here so the three flows produce identical text — paste one
/// row into a ticket or share the whole bundle and the format stays
/// consistent. Pure data → string; no UI imports.
class NetworkSerializer {
  NetworkSerializer._();

  /// Wraps [jsonEncode] with a fall-through to `toString()` for values that
  /// aren't JSON-encodable (streams, raw bytes, custom objects).
  static String _compactJson(Object? value) {
    if (value == null) return 'null';
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  /// Multi-line "everything we know about this request" dump — same shape
  /// as the bulk export, so the format is consistent regardless of entry
  /// count.
  static String formatEntry(NetworkEntry e) {
    final buf = StringBuffer()
      ..writeln('[${e.requestTime.toIso8601String()}] '
          '${e.methodLabel} ${e.url}')
      ..writeln('  status: ${HttpStatusCodes.labelFor(e.statusCode)}')
      ..writeln('  duration: ${e.durationMs ?? '—'} ms');
    if (e.contentType != null) {
      buf.writeln('  content-type: ${e.contentType}');
    }
    if (e.responseType != null) {
      buf.writeln('  response-type: ${e.responseType}');
    }
    if (e.queryParameters.isNotEmpty) {
      buf.writeln('  query: ${e.queryParameters}');
    }
    if (e.requestHeaders.isNotEmpty) {
      buf.writeln('  request-headers:');
      e.requestHeaders.forEach((k, v) => buf.writeln('    $k: $v'));
    }
    if (e.requestBody != null) {
      buf.writeln('  request-body: ${_compactJson(e.requestBody)}');
    }
    if (e.responseHeaders.isNotEmpty) {
      buf.writeln('  response-headers:');
      e.responseHeaders.forEach((k, v) => buf.writeln('    $k: $v'));
    }
    if (e.responseBody != null) {
      buf.writeln('  response-body: ${_compactJson(e.responseBody)}');
    }
    if (e.error != null) {
      buf.writeln('  error: ${e.error}');
    }
    if (e.curl != null) {
      buf.writeln('  curl: ${e.curl}');
    }
    return buf.toString();
  }

  /// Compact "cURL on top, response below" — what the per-row copy icon
  /// dumps into the share sheet. Designed for pasting into a bug ticket.
  static String formatCurlPlusResponse(NetworkEntry e) {
    final buf = StringBuffer();
    if (e.curl != null) {
      buf.writeln(e.curl);
      buf.writeln();
    }
    buf.writeln('# Response');
    if (e.statusCode != null) buf.writeln('# status: ${e.statusCode}');
    if (e.error != null) buf.writeln('# error: ${e.error}');
    if (e.responseBody != null) {
      buf.writeln(_compactJson(e.responseBody));
    } else {
      buf.writeln('(no body)');
    }
    return buf.toString();
  }

  /// Full export bundle — header block + one [formatEntry] per row,
  /// separated by hyphens for readability.
  static String formatBundle(List<NetworkEntry> records) {
    final buf = StringBuffer()
      ..writeln('DebugLens network export')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Requests: ${records.length}')
      ..writeln('=' * 60);
    for (final r in records) {
      buf.writeln(formatEntry(r));
      buf.writeln('-' * 60);
    }
    return buf.toString();
  }

  /// Returns the captured cURL if the interceptor pre-rendered one, otherwise
  /// constructs a best-effort cURL inline. Falls back so manually-built
  /// `NetworkEntry`s (e.g. mock data) still get a usable command.
  static String renderCurl(NetworkEntry e) {
    if (e.curl != null) return e.curl!;
    final b = StringBuffer('curl -X ${e.methodLabel}');
    e.requestHeaders.forEach((k, v) => b.write(" \\\n  -H '$k: $v'"));
    if (e.requestBody != null) {
      b.write(" \\\n  -d '${jsonEncode(e.requestBody)}'");
    }
    b.write(" \\\n  '${e.url}'");
    return b.toString();
  }
}
