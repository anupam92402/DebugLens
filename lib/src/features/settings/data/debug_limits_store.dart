import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../shared/debug_constants.dart';
import '../../logs/data/debug_lens_logger.dart';
import '../../storage/data/debug_shared_prefs_source.dart';
import '../domain/debug_limit.dart';

/// The panel's editable retention limits.
///
/// Held in memory so the capture paths can read a cap synchronously while
/// trimming — [of] always answers, falling back to [DebugLimit.fallback] before
/// [restore] has run. Persisted as one JSON map so a raised limit survives a
/// relaunch.
///
/// A `ChangeNotifier` so the limits sheet re-renders as values are edited.
class DebugLimits extends ChangeNotifier {
  DebugLimits._();

  static final DebugLimits instance = DebugLimits._();

  final Map<DebugLimit, int> _values = <DebugLimit, int>{};

  /// The cap in force for [limit].
  int of(DebugLimit limit) => _values[limit] ?? limit.fallback;

  /// Whether [limit] has been changed from its shipped default.
  bool isCustom(DebugLimit limit) => _values.containsKey(limit);

  /// Loads the saved limits. Called once from `DebugLens.wrap`.
  Future<void> restore() async {
    final raw = await DebugLensSharedPrefs.getString(
      DebugConstants.limitsPrefsKey,
    );
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final limit in DebugLimit.values) {
        final value = decoded[limit.name];
        // Ignore anything out of range: the bounds may have tightened since it
        // was written, and a stored limit should never outvote them.
        if (value is int && DebugLimit.accepts(value)) _values[limit] = value;
      }
    } catch (_) {
      /// Unreadable (hand-edited, or an older shape) — keep the defaults.
      return;
    }
    _applyLogs();
    notifyListeners();
  }

  /// Sets [limit] to [value] and persists it. The caller is expected to have
  /// validated against [DebugLimit.accepts]; an out-of-range value is ignored
  /// rather than stored.
  Future<void> set(DebugLimit limit, int value) async {
    if (!DebugLimit.accepts(value)) return;
    _values[limit] = value;
    if (limit == DebugLimit.logs) _applyLogs();
    notifyListeners();
    await _write();
  }

  /// Returns [limit] to its shipped default.
  Future<void> reset(DebugLimit limit) async {
    if (_values.remove(limit) == null) return;
    if (limit == DebugLimit.logs) _applyLogs();
    notifyListeners();
    await _write();
  }

  /// The logger owns its own buffer and trims on write, so its cap has to be
  /// pushed across rather than read from here.
  void _applyLogs() =>
      DebugLensLogger.instance.maxHistory = of(DebugLimit.logs);

  Future<void> _write() => DebugLensSharedPrefs.setString(
    DebugConstants.limitsPrefsKey,
    _values.isEmpty
        ? null
        : jsonEncode({for (final e in _values.entries) e.key.name: e.value}),
  );
}
