import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../shared/debug_constants.dart';
import '../../logs/data/debug_lens_logger.dart';
import '../../storage/data/debug_shared_prefs_source.dart';
import '../domain/debug_limit.dart';
import '../domain/debug_lens_limits.dart';

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

  /// Limits the host asked for — set through `DebugLens.initialLimits`.
  ///
  /// Consulted per feed, and only where nothing is saved for that feed, so a
  /// device edit outranks the host and the host outranks the shipped default.
  static DebugLensLimits initial = const DebugLensLimits();

  /// The cap in force for [limit] — saved edit, else host seed, else shipped.
  int of(DebugLimit limit) =>
      _values[limit] ?? initial.valueOf(limit) ?? limit.fallback;

  /// Whether [limit] has been edited on this device.
  ///
  /// A host seed doesn't count: it is that build's default, which is what Reset
  /// in the limits sheet puts the feed back to.
  bool isCustom(DebugLimit limit) => _values.containsKey(limit);

  /// Loads the saved limits. Called once from `DebugLens.wrap`.
  Future<void> restore() async {
    final raw = await DebugLensSharedPrefs.getString(
      DebugConstants.limitsPrefsKey,
    );
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final limit in DebugLimit.values) {
          final value = decoded[limit.name];
          // Ignore anything out of range: the bounds may have tightened since it
          // was written, and a stored limit should never outvote them.
          if (value is int && DebugLimit.accepts(value)) _values[limit] = value;
        }
      } catch (_) {
        // Unreadable (hand-edited, or an older shape) — keep what we have.
      }
    }
    // Unconditional: the logger owns its own buffer, so a host-seeded logs cap
    // has to be pushed across even when this device has nothing saved.
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
  void _applyLogs() => DebugLensLogger().maxHistory = of(DebugLimit.logs);

  Future<void> _write() => DebugLensSharedPrefs.setString(
    DebugConstants.limitsPrefsKey,
    _values.isEmpty
        ? null
        : jsonEncode({for (final e in _values.entries) e.key.name: e.value}),
  );
}
