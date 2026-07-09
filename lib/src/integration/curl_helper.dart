import 'dart:convert';

import 'package:dio/dio.dart';

/// Renders a copy-pasteable `curl` command for a Dio [RequestOptions].
///
/// Adapted from `we_logger/talker_dio_logger/helper/curl_helper.dart` —
/// kept self-contained so the rest of debug_lens stays Dio-agnostic at the
/// import level.
class CurlHelper {
  CurlHelper._();

  /// Returns the cURL representation, or `null` if rendering fails for any
  /// reason (e.g. non-JSON-serialisable body). Never throws.
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
