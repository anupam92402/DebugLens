import 'package:flutter/foundation.dart';

/// A titled group of `key -> value` facts shown on a Firebase service screen
/// (e.g. a "Status" group, or a "Parameters" group for Remote Config).
@immutable
class DebugLensInfoGroup {
  final String title;
  final Map<String, String> values;

  /// Keys whose values are secret (API keys, tokens, …). Their rows render
  /// masked with a tap-to-reveal toggle on the service screen.
  final Set<String> sensitiveKeys;

  const DebugLensInfoGroup({
    required this.title,
    this.values = const {},
    this.sensitiveKeys = const {},
  });

  /// Whether [key]'s value should be masked in the UI.
  bool isSensitive(String key) => sensitiveKeys.contains(key);
}
