import 'package:flutter/foundation.dart';

/// A titled block of `key -> value` facts shown on a service screen.
@immutable
class DebugLensServiceGroup {
  final String title;

  /// Optional secondary line under the title (e.g. a timestamp).
  final String? subtitle;

  final Map<String, String> values;

  const DebugLensServiceGroup({
    required this.title,
    this.subtitle,
    this.values = const {},
  });
}
