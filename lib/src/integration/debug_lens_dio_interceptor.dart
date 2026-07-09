import 'package:dio/dio.dart';

import '../core/debug_lens_logger.dart';
import '../core/debug_store.dart';
import '../core/models/network_entry.dart';
import 'curl_helper.dart';

/// A Dio [Interceptor] that mirrors every HTTP transaction into DebugLens.
///
/// - On request: appends a [NetworkEntry] in the `pending` state.
/// - On response: replaces the pending entry with one carrying the status,
///   body, headers, and timing.
/// - On error: same, but with the error string populated.
///
/// Each lifecycle also emits a `DebugLensLogger` entry tagged
/// `network.<METHOD>` so the Logs screen shows it alongside other logs.
///
/// Install once on each Dio you want to observe:
///
/// ```dart
/// final dio = Dio()..interceptors.add(DebugLensDioInterceptor());
/// ```
///
/// Modelled after `TalkerDioLogger` in `we_logger` — same structural hooks,
/// adapted to debug_lens's typed [NetworkEntry] / [DebugStore] model.
class DebugLensDioInterceptor extends Interceptor {
  DebugLensDioInterceptor({
    this.settings = const DebugLensDioInterceptorSettings(),
    DebugStore? store,
  }) : _store = store ?? DebugStore.instance;

  final DebugStore _store;

  /// Per-interceptor options — gate logging, body capture, header redaction.
  final DebugLensDioInterceptorSettings settings;

  /// Map RequestOptions identity → the entry's id, so onResponse / onError can
  /// find and update the right pending entry. `Expando` would be cleaner but
  /// `RequestOptions` is mutable & shared, so we just key on `hashCode`.
  final Map<int, String> _idByRequest = {};

  /// Map RequestOptions identity → request start time, so we can compute
  /// `durationMs` when the response arrives.
  final Map<int, DateTime> _startByRequest = {};

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

  /// Stringifies headers and optionally redacts sensitive ones. Dio's header
  /// values are `List<String>` (per spec); we collapse to a comma-joined
  /// string for display.
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

  /// Best-effort byte count for the request/response payload. Returns null
  /// when the size isn't readily knowable.
  int? _byteSizeOf(Object? body) {
    if (body == null) return null;
    if (body is String) return body.length;
    if (body is List<int>) return body.length;
    return null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
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
      requestBytes: settings.captureRequestBody ? _byteSizeOf(options.data) : null,
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
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
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
      responseBody:
          settings.captureResponseBody ? err.response?.data : null,
      error: err.message ?? err.toString(),
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

    // RE-SNAPSHOT the entire request side from the current [options] —
    // interceptors that run AFTER ours can mutate it before the request is
    // actually sent. Concrete example: in the OperatorAppFlutter stack
    // `WEDefaultHeaderInterceptor` is registered via `WEDioClient
    // .getDioObject()` and ends up at the END of the chain, so it injects
    // `token` / `X-APP-PLATFORM` / `X-DEVICE-ID` / etc. only after our
    // onRequest has already captured. By onResponse / onError, those
    // additions are present in `options.headers`, so we re-read everything
    // to land a complete picture in the Network screen.
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
      requestBytes:
          settings.captureRequestBody ? _byteSizeOf(options.data) : null,
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
          '${completed.methodLabel} ${statusCode ?? '—'} '
          '${completed.url} (${durationMs ?? '?'}ms): $error',
          name: tag,
        );
      } else {
        DebugLensLogger().d(
          '${completed.methodLabel} ${statusCode ?? '?'} '
          '${completed.url} (${durationMs ?? '?'}ms)',
          name: tag,
        );
      }
    }
  }
}

/// Configuration knobs for [DebugLensDioInterceptor]. All fields are
/// `const`-friendly so the default can live as a `const` literal.
class DebugLensDioInterceptorSettings {
  /// When `true`, every captured request / response / error also emits a
  /// `DebugLensLogger` entry. Set `false` to keep the Network screen alone
  /// without mirroring into Logs.
  final bool logToLogger;

  /// Whether to copy the request body into the entry. Disable for very large
  /// uploads or PII-sensitive payloads.
  final bool captureRequestBody;

  /// Whether to copy the response body into the entry. Disable for very
  /// large downloads or streamed responses.
  final bool captureResponseBody;

  /// Replaces values of `Authorization` and `Cookie` headers with
  /// `••• redacted •••` in the captured entry. Defaults to `true`.
  final bool redactSensitiveHeaders;

  const DebugLensDioInterceptorSettings({
    this.logToLogger = true,
    this.captureRequestBody = true,
    this.captureResponseBody = true,
    this.redactSensitiveHeaders = true,
  });
}
