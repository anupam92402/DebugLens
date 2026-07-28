import 'package:flutter/foundation.dart';

import '../../../core/debug_lens_config.dart';
import '../../../shared/debug_constants.dart';
import '../../storage/data/debug_shared_prefs_source.dart';

/// Device-local override for the app's version string.
///
/// Same shape as `DebugConfigStore`: the host hands its real version over once
/// at startup through `DebugLens.instance.setAppVersion`, and reads back
/// through [version] — so a tester can pin the app to another version without
/// the host writing any of the plumbing.
///
/// **Edits apply on the next app start.** [load] snapshots the saved override
/// into [_activated], which is what [version] answers from; a later edit only
/// touches [_override], so the dialog shows the new value immediately but the
/// app keeps reporting the old one until it relaunches. Matching Remote Config
/// here is deliberate — a version that changed mid-session would disagree with
/// whatever the app had already sent upstream.
class AppVersionStore extends ChangeNotifier {
  AppVersionStore._();

  static final AppVersionStore instance = AppVersionStore._();

  /// What the host registered — the real bundle version.
  String _source = '';

  /// Saved override, awaiting the next start. Empty means none.
  String _override = '';

  /// The override in force this session, snapshotted at [load].
  String _activated = '';

  /// The version the host reported. Also what Reset restores.
  String get source => _source;

  /// The version in force **this session** — what the app should show.
  String get version => _activated.isEmpty ? _source : _activated;

  /// The override as it will apply next start, or [source] when there is none.
  /// This is what the edit dialog opens on.
  String get pending => _override.isEmpty ? _source : _override;

  /// Whether an override is set, whether or not it has taken effect yet.
  bool get isOverridden => _override.isNotEmpty;

  /// Whether the saved override hasn't been picked up yet — true between
  /// editing and relaunching.
  bool get awaitingRestart => _override != _activated;

  /// Takes [version] as the source of truth and resolves what this session
  /// serves. Call once at startup, awaited.
  Future<void> load(String version) async {
    _source = version;
    // As with remote config: disabled means the host's own version is what
    // `version` reports, whatever is saved.
    if (!DebugLensConfig.enabled) {
      _override = '';
      _activated = '';
      notifyListeners();
      return;
    }
    _override =
        await DebugLensSharedPrefs.getString(
          DebugConstants.appVersionPrefsKey,
        ) ??
        '';
    _activated = _override;
    notifyListeners();
  }

  /// Sets the override. Ignores a blank value, and treats one equal to the
  /// source as clearing it — otherwise "overridden" would be true for a value
  /// that changes nothing.
  Future<void> setOverride(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _source) return reset();
    if (trimmed == _override) return;
    _override = trimmed;
    notifyListeners();
    await _write();
  }

  /// Drops the override, so the next start reports the host's version again.
  Future<void> reset() async {
    if (_override.isEmpty) return;
    _override = '';
    notifyListeners();
    await _write();
  }

  Future<void> _write() => DebugLensSharedPrefs.setString(
    DebugConstants.appVersionPrefsKey,
    _override.isEmpty ? null : _override,
  );
}
