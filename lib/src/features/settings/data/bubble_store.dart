import 'package:flutter/foundation.dart';

import '../../../shared/debug_constants.dart';
import '../../storage/data/debug_shared_prefs_source.dart';
import '../domain/bubble_style.dart';

/// How the panel's bubble looks and where it sits.
class BubbleStore extends ChangeNotifier {
  BubbleStore._();

  static final BubbleStore instance = BubbleStore._();

  BubbleIcon _icon = BubbleIcon.fallback;
  BubbleCorner _corner = BubbleCorner.fallback;

  BubbleIcon get icon => _icon;
  BubbleCorner get corner => _corner;

  /// Whether either value has been changed from the shipped default.
  bool get isCustom =>
      _icon != BubbleIcon.fallback || _corner != BubbleCorner.fallback;

  /// Loads both values. Called once from `DebugLens.wrap`.
  Future<void> restore() async {
    _icon = BubbleIcon.byName(
      await DebugLensSharedPrefs.getString(DebugConstants.bubbleIconPrefsKey),
    );
    _corner = BubbleCorner.byName(
      await DebugLensSharedPrefs.getString(DebugConstants.bubbleCornerPrefsKey),
    );
    notifyListeners();
  }

  Future<void> setIcon(BubbleIcon icon) async {
    if (_icon == icon) return;
    _icon = icon;
    notifyListeners();
    await DebugLensSharedPrefs.setString(
      DebugConstants.bubbleIconPrefsKey,
      icon.name,
    );
  }

  Future<void> setCorner(BubbleCorner corner) async {
    if (_corner == corner) return;
    _corner = corner;
    notifyListeners();
    await DebugLensSharedPrefs.setString(
      DebugConstants.bubbleCornerPrefsKey,
      corner.name,
    );
  }
}
