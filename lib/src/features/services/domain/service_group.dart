import 'package:flutter/foundation.dart';

/// A titled block of `key -> value` facts shown on a service screen.
@immutable
class DebugLensServiceGroup {
  /// The block's heading.
  final String title;

  /// Optional secondary line under the title (e.g. a timestamp).
  final String? subtitle;

  /// The facts themselves, rendered as one `key: value` row each, in
  /// insertion order.
  final Map<String, String> values;

  /// Builds one block for a service screen.
  const DebugLensServiceGroup({
    required this.title,
    this.subtitle,
    this.values = const {},
  });
}
