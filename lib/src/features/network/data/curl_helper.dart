import 'dart:convert';

import 'package:dio/dio.dart';

/// Renders a copy-pasteable `curl` command for a Dio [RequestOptions].
class CurlHelper {
  CurlHelper._();

  /// Returns the cURL string, or `null` if rendering fails (never throws).
  static String? render(RequestOptions options) {
    try {
      final parts = <String>['curl -i'];
      if (options.method.toUpperCase() != 'GET') {
        parts.add('-X ${options.method}');
      }
      options.headers.forEach((k, v) {
        // `Cookie` is intentionally skipped — curl picks it up from the jar.
        if (k != 'Cookie') parts.add('-H "$k: $v"');
      });
      if (options.data != null) {
        // FormData can't be JSON-serialised — collapse to its fields so the
        // generated cURL is at least a valid shell command.
        Object? data = options.data;
        if (data is FormData) {
          data = Map.fromEntries(data.fields);
        }
        final encoded = json.encode(data).replaceAll('"', r'\"');
        parts.add('-d "$encoded"');
      }
      parts.add('"${options.uri}"');
      return parts.join(' \\\n\t');
    } catch (_) {
      return null;
    }
  }
}
