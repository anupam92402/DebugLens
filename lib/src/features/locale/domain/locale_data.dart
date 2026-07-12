import 'package:flutter/foundation.dart';

/// A read-only snapshot of the app's active locale strings. [entries] may be
/// nested (`{category: {key: value}}`) or flat (`{key: value}`); the screen
/// flattens/groups at display time. No copy is kept.
@immutable
class DebugLensLocaleData {
  /// The active locale strings. Nested or flat; see [flatten].
  final Map<String, dynamic> entries;

  /// Human-readable label for the active locale (e.g. 'English', 'Hindi').
  final String label;

  const DebugLensLocaleData({required this.entries, this.label = ''});

  /// An empty snapshot — rendered as the "No locale entries" empty state.
  static const DebugLensLocaleData empty = DebugLensLocaleData(
    entries: {},
    label: '',
  );

  /// Flattens [entries] to `key → value`. A nested category
  /// `{PAYMENT: {PAYMENT_ISSUES: "…"}}` becomes `PAYMENT.PAYMENT_ISSUES → "…"`;
  /// top-level scalars are kept as-is. Pure — no state is retained.
  Map<String, String> flatten() {
    final flat = <String, String>{};
    entries.forEach((category, value) {
      if (value is Map) {
        value.forEach((key, v) {
          flat['$category.$key'] = v.toString();
        });
      } else {
        flat[category] = value.toString();
      }
    });
    return flat;
  }

  /// Groups [entries] by their top-level category for the collapsible Locale
  /// view: `{ACTION: {ACTION_REQUIRED: "…", …}, PAYMENT: {…}}`. Each nested
  /// category maps to its own `key → value` block. Top-level scalars (no inner
  /// map) are collected under [scalarGroup]. Pure — no state is retained.
  Map<String, Map<String, String>> group() {
    final grouped = <String, Map<String, String>>{};
    entries.forEach((category, value) {
      if (value is Map) {
        final inner = <String, String>{};
        value.forEach((key, v) => inner[key.toString()] = v.toString());
        grouped[category] = inner;
      } else {
        (grouped[scalarGroup] ??= <String, String>{})[category] = value
            .toString();
      }
    });
    return grouped;
  }

  /// Bucket name used by [group] for top-level scalar entries that have no
  /// category map of their own.
  static const String scalarGroup = 'OTHER';
}
