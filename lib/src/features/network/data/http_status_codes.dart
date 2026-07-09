import '../../../shared/debug_constants.dart';

/// IANA reason phrases for the most common HTTP status codes — used in the
/// Network list/detail UI to show `200 OK`, `404 Not Found`, etc.
///
/// Curated from `chucker_lib/src/helpers/status_code_map.dart` (we_logger) —
/// trimmed to the codes actually seen in practice. Falls back to the class
/// (`2xx Success`, `4xx Client Error`, …) for anything not in the table.
class HttpStatusCodes {
  HttpStatusCodes._();

  static const Map<int, String> _phrases = {
    100: 'Continue',
    101: 'Switching Protocols',

    200: 'OK',
    201: 'Created',
    202: 'Accepted',
    204: 'No Content',
    206: 'Partial Content',

    301: 'Moved Permanently',
    302: 'Found',
    303: 'See Other',
    304: 'Not Modified',
    307: 'Temporary Redirect',
    308: 'Permanent Redirect',

    400: 'Bad Request',
    401: 'Unauthorized',
    402: 'Payment Required',
    403: 'Forbidden',
    404: 'Not Found',
    405: 'Method Not Allowed',
    408: 'Request Timeout',
    409: 'Conflict',
    410: 'Gone',
    413: 'Payload Too Large',
    415: 'Unsupported Media Type',
    422: 'Unprocessable Entity',
    429: 'Too Many Requests',

    500: 'Internal Server Error',
    501: 'Not Implemented',
    502: 'Bad Gateway',
    503: 'Service Unavailable',
    504: 'Gateway Timeout',
    505: 'HTTP Version Not Supported',
  };

  /// Returns the reason phrase for [code], falling back to a class label.
  /// Returns `null` for invalid codes (<100 or >=600).
  static String? reasonPhrase(int? code) {
    if (code == null) return null;
    final exact = _phrases[code];
    if (exact != null) return exact;
    if (code >= 100 && code < 200) return 'Informational';
    if (code >= 200 && code < 300) return 'Success';
    if (code >= 300 && code < 400) return 'Redirection';
    if (code >= 400 && code < 500) return 'Client Error';
    if (code >= 500 && code < 600) return 'Server Error';
    return null;
  }

  /// Returns `"<code> <phrase>"`, or just the code if no phrase exists.
  static String labelFor(int? code) {
    if (code == null) return DebugConstants.emptyValue;
    final phrase = reasonPhrase(code);
    return phrase == null ? '$code' : '$code $phrase';
  }
}
