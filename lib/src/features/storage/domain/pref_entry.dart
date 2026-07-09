import 'package:flutter/foundation.dart';

/// One SharedPreferences entry, as handed to DebugLens for display.
///
/// [value] is always the readable string form (the underlying store serializes
/// scalars to text before persisting, so there is no original int/bool/double
/// type to recover). [encrypted] marks entries that were stored through the
/// app's encrypted preferences (vs. plaintext keys written by plugins or the
/// framework) — the Storage screen flags these with a `*`.
@immutable
class DebugLensPrefEntry {
  final String key;
  final String value;
  final bool encrypted;

  const DebugLensPrefEntry({
    required this.key,
    required this.value,
    this.encrypted = false,
  });
}
