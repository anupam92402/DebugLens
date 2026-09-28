import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../features/storage/data/debug_shared_prefs_source.dart';
import '../shared/debug_constants.dart';
import 'debug_routes.dart';
import 'panel_tab.dart';

/// How often each tab is opened, and which tabs fill the bar's slots after the
/// pinned Network tab. Loaded once at startup; the slots change only in
/// [startSession] and [reset], and stay as they are while [adaptive] is off.
class TabUsageStore extends ChangeNotifier {
  TabUsageStore._();

  static final TabUsageStore instance = TabUsageStore._();

  /// Bar slots after Network on a fresh install.
  static const List<String> defaultSlots = [
    DebugRoutes.logs,
    DebugRoutes.analytics,
    DebugRoutes.navigation,
  ];

  final Map<String, double> _scores = {};
  List<String> _slots = List.of(defaultSlots);
  bool _adaptive = true;

  /// Whether [restore] has already run this session.
  bool _restored = false;

  List<String> get slots => List.unmodifiable(_slots);

  /// Whether usage is counted and the slots can change.
  bool get adaptive => _adaptive;

  /// Whether the slots differ from [defaultSlots].
  bool get isCustom => !listEquals(_slots, defaultSlots);

  double _scoreOf(String route) => _scores[route] ?? 0;

  /// Loads scores and slots. Guarded like `BubbleStore.restore`, since
  /// `DebugLens.wrap` runs on every rebuild.
  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    try {
      _adaptive =
          await DebugLensSharedPrefs.getString(
            DebugConstants.tabAdaptivePrefsKey,
          ) !=
          DebugConstants.falseValue;
      final rawScores = await DebugLensSharedPrefs.getString(
        DebugConstants.tabUsagePrefsKey,
      );
      if (rawScores != null) {
        (jsonDecode(rawScores) as Map<String, dynamic>).forEach((route, v) {
          if (v is num) _scores[route] = v.toDouble();
        });
      }
      final rawSlots = await DebugLensSharedPrefs.getString(
        DebugConstants.tabSlotsPrefsKey,
      );
      if (rawSlots != null) {
        final saved = List<String>.from(jsonDecode(rawSlots) as List);
        final known = {for (final t in PanelTab.all) t.route};
        final valid =
            saved.length == defaultSlots.length &&
            saved.toSet().length == saved.length &&
            saved.every((r) => known.contains(r) && r != DebugRoutes.network);
        if (valid) _slots = saved;
      }
    } catch (_) {
      // Unreadable — keep the defaults.
    }
  }

  /// Counts an open of [route] from the bar or More. Moves nothing until the
  /// next [startSession].
  void recordOpen(String route) {
    if (!_adaptive) return;
    _scores[route] = _scoreOf(route) + 1;
    _saveScores();
  }

  /// Runs as the panel opens: fades past usage, then gives the weakest slot
  /// among [visible] tabs to the strongest More tab, at most once.
  void startSession(Set<String> visible) {
    if (!_adaptive) return;
    for (final route in _scores.keys.toList()) {
      final faded = _scores[route]! * DebugConstants.tabUsageDecay;
      if (faded < DebugConstants.tabUsageFloor) {
        _scores.remove(route);
      } else {
        _scores[route] = faded;
      }
    }
    _saveScores();

    String? weakest;
    var weakestScore = double.infinity;
    for (final route in _slots) {
      if (!visible.contains(route)) continue;
      final score = _scoreOf(route);
      // `<=`: on a tie the rightmost slot goes, keeping the earlier ones.
      if (score <= weakestScore) {
        weakest = route;
        weakestScore = score;
      }
    }
    if (weakest == null) return;

    final inBar = {DebugRoutes.network, ..._slots};
    String? strongest;
    var strongestScore = -1.0;
    for (final tab in PanelTab.all) {
      if (inBar.contains(tab.route) || !visible.contains(tab.route)) continue;
      final score = _scoreOf(tab.route);
      if (score > strongestScore) {
        strongest = tab.route;
        strongestScore = score;
      }
    }
    if (strongest == null ||
        strongestScore < DebugConstants.tabPromoteMinScore ||
        strongestScore < weakestScore * DebugConstants.tabPromoteRatio) {
      return;
    }
    _slots[_slots.indexOf(weakest)] = strongest;
    _saveSlots();
  }

  /// Turns adapting on or off. Off keeps the current bar as it is.
  Future<void> setAdaptive(bool on) async {
    if (_adaptive == on) return;
    _adaptive = on;
    notifyListeners();
    await DebugLensSharedPrefs.setString(
      DebugConstants.tabAdaptivePrefsKey,
      on ? DebugConstants.trueValue : DebugConstants.falseValue,
    );
  }

  /// Forgets all usage and puts the shipped slots back.
  Future<void> reset() async {
    _scores.clear();
    _slots = List.of(defaultSlots);
    notifyListeners();
    await DebugLensSharedPrefs.setString(DebugConstants.tabUsagePrefsKey, null);
    await DebugLensSharedPrefs.setString(DebugConstants.tabSlotsPrefsKey, null);
  }

  void _saveScores() => DebugLensSharedPrefs.setString(
    DebugConstants.tabUsagePrefsKey,
    jsonEncode(_scores),
  );

  void _saveSlots() => DebugLensSharedPrefs.setString(
    DebugConstants.tabSlotsPrefsKey,
    jsonEncode(_slots),
  );
}
