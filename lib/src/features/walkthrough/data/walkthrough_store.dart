import '../../../shared/debug_constants.dart';
import '../../storage/data/debug_shared_prefs_source.dart';

/// Whether the first-run tour has been shown.
///
/// Persisted, and read once per launch rather than watched: a tour that
/// reappears is worse than no tour, and a one-shot flag needs no notifier.
class WalkthroughStore {
  WalkthroughStore._();

  static final WalkthroughStore instance = WalkthroughStore._();

  /// Set as soon as the tour is shown, so the flag survives even if the panel
  /// is closed mid-tour — nobody wants to be walked through twice.
  bool _seenThisSession = false;

  Future<bool> hasSeen() async {
    if (_seenThisSession) return true;
    final saved = await DebugLensSharedPrefs.getString(
      DebugConstants.walkthroughPrefsKey,
    );
    return saved == DebugConstants.trueValue;
  }

  Future<void> markSeen() async {
    _seenThisSession = true;
    await DebugLensSharedPrefs.setString(
      DebugConstants.walkthroughPrefsKey,
      DebugConstants.trueValue,
    );
  }
}
