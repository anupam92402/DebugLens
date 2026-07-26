import 'package:flutter/foundation.dart';

import '../../../shared/debug_constants.dart';

/// A titled block of `key -> value` facts shown on a service screen.
/// Typically one block per record (an analytics event, a screen load, a crash
/// report) — its [title] is the record's primary label and [subtitle] an
/// optional secondary line (timestamp, duration, …).
@immutable
class DebugLensServiceGroup {
  final String title;

  /// Optional secondary line under the title (e.g. a timestamp).
  final String? subtitle;

  final Map<String, String> values;

  /// Keys whose values are secret (API keys, tokens, …). Their rows render
  /// masked behind a tap-to-reveal toggle, and are always redacted from shared
  /// log files — revealing on screen never puts a secret in an export.
  final Set<String> sensitiveKeys;

  const DebugLensServiceGroup({
    required this.title,
    this.subtitle,
    this.values = const {},
    this.sensitiveKeys = const {},
  });

  /// Whether [key]'s value should be masked in the UI.
  bool isSensitive(String key) => sensitiveKeys.contains(key);

  /// Whether any of [values] is marked sensitive — drives the reveal toggle.
  bool get hasSensitive => values.keys.any(isSensitive);

  /// [values] with every sensitive entry replaced by a mask. Used for display
  /// and copy while hidden, and always for shared log files.
  Map<String, String> get maskedValues => {
    for (final e in values.entries)
      e.key: isSensitive(e.key) ? DebugConstants.maskedValue : e.value,
  };
}
