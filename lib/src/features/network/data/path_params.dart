import '../../../shared/debug_strings.dart';

/// A URL's path parameters, detected: segments that look like ids, each keyed
/// by the static segment before it (`/users/42` → `users: 42`).
class PathParams {
  PathParams._();

  static final RegExp _number = RegExp(r'^\d+$');
  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Hex ids of 12+ characters with at least one digit, e.g. Mongo ObjectIds.
  static final RegExp _hexId = RegExp(r'^(?=.*\d)[0-9a-fA-F]{12,}$');

  /// Opaque tokens of 16+ characters mixing letters and digits.
  static final RegExp _token = RegExp(
    r'^(?=.*\d)(?=.*[A-Za-z])[A-Za-z0-9_-]{16,}$',
  );

  static bool _isValue(String segment) =>
      _number.hasMatch(segment) ||
      _uuid.hasMatch(segment) ||
      _hexId.hasMatch(segment) ||
      _token.hasMatch(segment);

  static Map<String, String> of(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final params = <String, String>{};
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (!_isValue(segment)) continue;
      final previous = i > 0 ? segments[i - 1] : null;
      var key = previous != null && !_isValue(previous)
          ? previous
          : DebugStrings.networkPathSegment(i + 1);
      if (params.containsKey(key)) key = '$key (${i + 1})';
      params[key] = segment;
    }
    return params;
  }
}
