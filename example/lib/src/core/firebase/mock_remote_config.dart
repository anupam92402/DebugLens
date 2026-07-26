import 'package:debug_lens/debug_lens.dart';

/// In-memory stand-in for `FirebaseRemoteConfig`.
///
/// The only file in the app that knows DebugLens exists. It fetches from
/// "Firebase", shares the fetched values once, and then answers each read from
/// whichever side is in force. Feature code just calls
/// `MockFirebase.remoteConfig.getInt('key')` and never learns which won.
///
/// Overriding, resetting, persistence and the Firebase/Custom switch all live
/// inside DebugLens. Nothing here implements any of it.
class MockRemoteConfig {
  MockRemoteConfig._();

  static final MockRemoteConfig instance = MockRemoteConfig._();

  /// What "Firebase" would return — the source of truth. The value types are
  /// real (`bool`, `int`, `double`, `String`), which is how DebugLens infers
  /// each parameter's type.
  static const Map<String, Object> _firebaseValues = {
    'home_header_title': 'Your day',
    'show_summary_card': true,
    'promo_banner_text': '🎉 20% off Pro — this week only',
    'home_layout_experiment': 'variant_b',
    'notification_batch_size': 4,
    'discount_percentage': 12.5,
    'api_timeout_seconds': 30,
  };

  Future<void> initialize() async {
    /// Stands in for `FirebaseRemoteConfig.fetchAndActivate()`.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    /// Share all fetched values with DebugLens. A real integration unwraps
    /// first — `getAll()` hands back `RemoteConfigValue`, not raw values:
    ///
    /// ```dart
    /// await DebugLens.instance.setRemoteConfigData({
    ///   for (final e in _firebase.getAll().entries) e.key: e.value.asString(),
    /// });
    /// ```
    await DebugLens.instance.setRemoteConfigData(
      _firebaseValues,
      sourceLabel: 'Firebase',
    );
  }

  // --- Reads (used by the app) ---------------------------------------------
  //
  // One line each: DebugLens holds the registered values too, so it returns the
  // override when one applies and the Firebase value otherwise. Nothing here
  // branches on the source or repeats the type coercion.

  /// The raw value, or null for an unknown key — for anything the typed
  /// getters below don't cover.
  Object? getKey(String key) => DebugLens.instance.getKey(key);

  String getString(String key) => DebugLens.instance.getString(key);

  bool getBool(String key) => DebugLens.instance.getBool(key);

  int getInt(String key) => DebugLens.instance.getInt(key);

  double getDouble(String key) => DebugLens.instance.getDouble(key);
}
