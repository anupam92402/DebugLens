import 'dart:convert';

import '../../../shared/debug_constants.dart';
import '../../../shared/util/clock_format.dart';
import '../domain/network_entry.dart';
import 'http_status_codes.dart';

/// Plain-text serializers for [NetworkEntry] shared by the detail/row copy &
/// share flows, so they all produce identical text. Pure — no UI.
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

  /// Overview → Request → Response text dump (no cURL — that's a separate
  /// share). Mirrors the three detail tabs for pasting into a ticket.
  static String formatSections(NetworkEntry e) {
    final buf = StringBuffer()
      ..writeln('=== OVERVIEW ===')
      ..writeln('URL: ${e.url}')
      ..writeln('Method: ${e.methodLabel}')
      ..writeln('Status: ${HttpStatusCodes.labelFor(e.statusCode)}')
      ..writeln('Request Time: ${ClockFormat.dateTime(e.requestTime)}')
      ..writeln(
        'Duration: ${e.durationMs == null ? DebugConstants.emptyValue : '${e.durationMs} ms'}',
      )
      ..writeln('Content-Type: ${e.contentType ?? DebugConstants.notAvailable}')
      ..writeln(
        'Response-Type: ${e.responseType ?? DebugConstants.notAvailable}',
      )
      ..writeln('Req size: ${e.requestBytes ?? 0} B')
      ..writeln('Resp size: ${e.responseBytes ?? 0} B');
    if (e.queryParameters.isNotEmpty) {
      buf.writeln('Query: ${e.queryParameters}');
    }

    buf
      ..writeln()
      ..writeln('=== REQUEST ===');
    if (e.requestHeaders.isNotEmpty) {
      buf.writeln('Headers:');
      e.requestHeaders.forEach((k, v) => buf.writeln('  $k: $v'));
    }
    buf.writeln(
      'Body: ${e.requestBody == null ? DebugConstants.emptyValue : _compactJson(e.requestBody)}',
    );

    buf
      ..writeln()
      ..writeln('=== RESPONSE ===');
    buf.writeln(
      'Body: ${e.responseBody == null ? DebugConstants.emptyValue : _compactJson(e.responseBody)}',
    );
    if (e.error != null) buf.writeln('Error: ${e.error}');

    return buf.toString();
  }

  /// Compact "cURL on top, response below" — what the swipe gesture dumps
  /// into the share sheet. Designed for pasting into a bug ticket.
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
