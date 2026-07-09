enum HttpMethod { get, post, put, patch, delete, head, options }

enum NetworkStatusKind { success, error, pending }

class NetworkEntry {
  final String id;
  final HttpMethod method;
  final String url;

  /// Optional base URL the request was issued against (when split). Populated
  /// by [DebugLensDioInterceptor]; manually-built entries can leave it null
  /// since [url] is always the full address.
  final String? baseUrl;

  /// Query parameters as a structured map (preserves types — values can be
  /// `String`, `int`, `List`, etc.). Empty when none.
  final Map<String, dynamic> queryParameters;

  /// `Content-Type` of the request (e.g. `application/json`). Convenience copy
  /// of `requestHeaders['content-type']` exposed as its own field because the
  /// detail screen surfaces it prominently.
  final String? contentType;

  /// Response decoding type (`json`, `plain`, `bytes`, `stream`). Populated
  /// by the Dio interceptor from `RequestOptions.responseType`.
  final String? responseType;

  final int? statusCode;
  final int? durationMs;
  final DateTime requestTime;
  final Map<String, String> requestHeaders;
  final Object? requestBody;
  final Map<String, String> responseHeaders;
  final Object? responseBody;
  final String? error;
  final int? requestBytes;
  final int? responseBytes;

  /// Pre-rendered cURL command for the request — captured at interception time
  /// so it survives the response body being released. Detail screen falls back
  /// to rendering on-the-fly when this is null (e.g. for hand-built entries).
  final String? curl;

  const NetworkEntry({
    required this.id,
    required this.method,
    required this.url,
    required this.requestTime,
    this.baseUrl,
    this.queryParameters = const {},
    this.contentType,
    this.responseType,
    this.statusCode,
    this.durationMs,
    this.requestHeaders = const {},
    this.requestBody,
    this.responseHeaders = const {},
    this.responseBody,
    this.error,
    this.requestBytes,
    this.responseBytes,
    this.curl,
  });

  /// Returns a copy with the response-side fields filled in. Used by the
  /// interceptor to swap a pending entry for the final one without mutating
  /// the original instance.
  NetworkEntry copyWith({
    int? statusCode,
    int? durationMs,
    Map<String, String>? responseHeaders,
    Object? responseBody,
    String? error,
    int? requestBytes,
    int? responseBytes,
    String? responseType,
    String? curl,
  }) {
    return NetworkEntry(
      id: id,
      method: method,
      url: url,
      baseUrl: baseUrl,
      queryParameters: queryParameters,
      contentType: contentType,
      responseType: responseType ?? this.responseType,
      requestTime: requestTime,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      statusCode: statusCode ?? this.statusCode,
      durationMs: durationMs ?? this.durationMs,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      error: error ?? this.error,
      requestBytes: requestBytes ?? this.requestBytes,
      responseBytes: responseBytes ?? this.responseBytes,
      curl: curl ?? this.curl,
    );
  }

  String get path {
    try {
      final uri = Uri.parse(url);
      return uri.path.isEmpty ? url : uri.path;
    } catch (_) {
      return url;
    }
  }

  bool get isPending => statusCode == null && error == null;

  NetworkStatusKind get statusKind {
    if (isPending) return NetworkStatusKind.pending;
    if (error != null || (statusCode != null && statusCode! >= 400)) {
      return NetworkStatusKind.error;
    }
    return NetworkStatusKind.success;
  }

  String get methodLabel => method.name.toUpperCase();
}
