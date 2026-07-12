import 'dart:convert';

import 'package:dio/dio.dart';

import '../../logs/data/debug_lens_logger.dart';
import '../../../core/debug_store.dart';
import '../../../shared/debug_constants.dart';
import '../../../shared/debug_strings.dart';
import '../domain/network_entry.dart';
import 'curl_helper.dart';

/// Dio [Interceptor] that mirrors every HTTP transaction into DebugLens:
/// appends a pending [NetworkEntry] on request, finalizes it on
/// response/error, and (optionally) mirrors each into the Logs feed.
/// Add one per Dio: `Dio()..interceptors.add(DebugLensDioInterceptor())`.
class DebugLensDioInterceptor extends Interceptor {
  DebugLensDioInterceptor({
    this.settings = const DebugLensDioInterceptorSettings(),
    DebugStore? store,
  }) : _store = store ?? DebugStore.instance;

  final DebugStore _store;

  /// Per-interceptor options — gate logging, body capture, header redaction.
  final DebugLensDioInterceptorSettings settings;

  /// RequestOptions identity → pending entry id, so the response/error can
  /// update the right entry.
  final Map<int, String> _idByRequest = {};

  /// RequestOptions identity → start time, for computing `durationMs`.
  final Map<int, DateTime> _startByRequest = {};

  /// Backstop age after which a still-pending request is treated as abandoned
  /// and pruned, so the tracking maps can't leak if a request never completes.
  static const Duration _pendingTimeout = Duration(minutes: 5);

  int _seq = 0;

  /// Generates a short, monotonically increasing id for each captured request.
  String _nextId() {
    _seq++;
    return 'dio_${DateTime.now().millisecondsSinceEpoch}_$_seq';
  }

  HttpMethod _methodOf(String m) {
    switch (m.toUpperCase()) {
      case 'GET':
        return HttpMethod.get;
      case 'POST':
        return HttpMethod.post;
      case 'PUT':
        return HttpMethod.put;
      case 'PATCH':
        return HttpMethod.patch;
      case 'DELETE':
        return HttpMethod.delete;
      case 'HEAD':
        return HttpMethod.head;
      case 'OPTIONS':
        return HttpMethod.options;
    }
    return HttpMethod.get;
  }

  /// Collapses Dio's `List<String>` header values to comma-joined strings and
  /// redacts sensitive ones when enabled.
  Map<String, String> _normalizeHeaders(Map<String, dynamic> headers) {
    final out = <String, String>{};
    headers.forEach((k, v) {
      final value = v is List ? v.join(', ') : v.toString();
      final lower = k.toLowerCase();
      if (settings.redactSensitiveHeaders &&
          (lower == 'authorization' || lower == 'cookie')) {
        out[k] = '••• redacted •••';
      } else {
        out[k] = value;
      }
    });
    return out;
  }

  /// Best-effort UTF-8 byte count for the request/response payload. Encodes
  /// JSON maps/lists so structured bodies report a real size (not 0). Returns
  /// null when the size isn't knowable (e.g. streams, FormData).
  int? _byteSizeOf(Object? body) {
    if (body == null) return null;
    if (body is List<int>) return body.length; // already raw bytes
    if (body is String) return utf8.encode(body).length;
    try {
      return utf8.encode(jsonEncode(body)).length;
    } catch (_) {
      return null;
    }
  }

  /// Removes tracking entries for requests that never completed (cancelled
  /// without an error hook, dropped, etc.) and closes out their store entry,
  /// so [_idByRequest] / [_startByRequest] can't grow unbounded.
  void _pruneStalePending() {
    final now = DateTime.now();
    final stale = [
      for (final e in _startByRequest.entries)
        if (now.difference(e.value) > _pendingTimeout) e.key,
    ];
    for (final key in stale) {
      final id = _idByRequest.remove(key);
      _startByRequest.remove(key);
      if (id != null) {
        _store.markNetworkError(id, DebugStrings.networkAbandoned);
      }
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _pruneStalePending();
    final id = _nextId();
    final key = identityHashCode(options);
    _idByRequest[key] = id;
    _startByRequest[key] = DateTime.now();

    final entry = NetworkEntry(
      id: id,
      method: _methodOf(options.method),
      url: options.uri.toString(),
      baseUrl: options.baseUrl.isEmpty ? null : options.baseUrl,
      queryParameters: Map<String, dynamic>.from(options.queryParameters),
      contentType: options.contentType,
      responseType: options.responseType.name,
      requestTime: _startByRequest[key]!,
      requestHeaders: _normalizeHeaders(options.headers),
      requestBody: settings.captureRequestBody ? options.data : null,
      requestBytes: settings.captureRequestBody
          ? _byteSizeOf(options.data)
          : null,
      curl: CurlHelper.render(options),
    );
    _store.recordNetwork(entry);

    if (settings.logToLogger) {
      DebugLensLogger().d(
        '${entry.methodLabel} ${entry.url}',
        name: 'network.${entry.methodLabel}',
      );
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _finalize(
      response.requestOptions,
      statusCode: response.statusCode,
      responseHeaders: _normalizeHeaders(response.headers.map),
      responseBody: settings.captureResponseBody ? response.data : null,
      error: null,
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _finalize(
      err.requestOptions,
      statusCode: err.response?.statusCode,
      responseHeaders: err.response == null
          ? const <String, String>{}
          : _normalizeHeaders(err.response!.headers.map),
      responseBody: settings.captureResponseBody ? err.response?.data : null,
      error: err.type == DioExceptionType.cancel
          ? DebugStrings.networkCancelled
          : (err.message ?? err.toString()),
    );
    super.onError(err, handler);
  }

  void _finalize(
    RequestOptions options, {
    required int? statusCode,
    required Map<String, String> responseHeaders,
    required Object? responseBody,
    required String? error,
  }) {
    final key = identityHashCode(options);
    final id = _idByRequest.remove(key);
    final start = _startByRequest.remove(key);
    if (id == null) return; // request wasn't captured — nothing to update

    final durationMs = start == null
        ? null
        : DateTime.now().difference(start).inMilliseconds;

    // Re-snapshot the request side: later interceptors can add headers (e.g.
    // auth) after our onRequest ran, so re-read options for a complete entry.
    final completed = NetworkEntry(
      id: id,
      method: _methodOf(options.method),
      url: options.uri.toString(),
      baseUrl: options.baseUrl.isEmpty ? null : options.baseUrl,
      queryParameters: Map<String, dynamic>.from(options.queryParameters),
      contentType: options.contentType,
      responseType: options.responseType.name,
      requestTime: start ?? DateTime.now(),
      requestHeaders: _normalizeHeaders(options.headers),
      requestBody: settings.captureRequestBody ? options.data : null,
      requestBytes: settings.captureRequestBody
          ? _byteSizeOf(options.data)
          : null,
      curl: CurlHelper.render(options),
      statusCode: statusCode,
      durationMs: durationMs,
      responseHeaders: responseHeaders,
      responseBody: responseBody,
      responseBytes: _byteSizeOf(responseBody),
      error: error,
    );
    _store.updateNetwork(completed);

    if (settings.logToLogger) {
      final tag = 'network.${completed.methodLabel}';
      if (error != null) {
        DebugLensLogger().e(
          '${completed.methodLabel} ${statusCode ?? DebugConstants.emptyValue} '
          '${completed.url} (${durationMs ?? DebugConstants.unknownValue}ms): $error',
          name: tag,
        );
      } else {
        DebugLensLogger().d(
          '${completed.methodLabel} ${statusCode ?? DebugConstants.unknownValue} '
          '${completed.url} (${durationMs ?? DebugConstants.unknownValue}ms)',
          name: tag,
        );
      }
    }
  }
}

/// Configuration for [DebugLensDioInterceptor].
class DebugLensDioInterceptorSettings {
  /// Also mirror each transaction into the Logs feed.
  final bool logToLogger;

  /// Capture the request body (disable for large/PII uploads).
  final bool captureRequestBody;

  /// Capture the response body (disable for large/streamed downloads).
  final bool captureResponseBody;

  /// Redact `Authorization` / `Cookie` header values.
  final bool redactSensitiveHeaders;

  const DebugLensDioInterceptorSettings({
    this.logToLogger = true,
    this.captureRequestBody = true,
    this.captureResponseBody = true,
    this.redactSensitiveHeaders = true,
  });
}
