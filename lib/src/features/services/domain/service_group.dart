import 'package:flutter/foundation.dart';

/// A titled block of `key -> value` facts shown on a service screen.
/// Typically one block per record (an analytics event, a screen load, a crash
/// report) — its [title] is the record's primary label and [subtitle] an
/// optional secondary line (timestamp, duration, …).
///
/// Values are rendered and exported as given. A host that must not surface a
/// secret should not put it in [values] in the first place — DebugLens does no
/// masking of its own.
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
