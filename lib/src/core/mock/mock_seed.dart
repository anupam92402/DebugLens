import '../../features/network/domain/network_entry.dart';
import '../../features/notifications/domain/notification_entry.dart';
import '../../features/notifications/domain/deeplink_entry.dart';
import '../../features/device/domain/device_app_info.dart';

/// Static sample data so every screen is populated during UI review.
/// Replaced by real capture sources when each feature is implemented.
class MockSeed {
  static DateTime _ago(int seconds) =>
      DateTime.now().subtract(Duration(seconds: seconds));

  /// Network entries start empty — populated entirely by
  /// `DebugLensDioInterceptor` once the interceptor is attached to a Dio.
  static List<NetworkEntry> network() => [];

  static List<NotificationEntry> notifications() => [
    NotificationEntry(
      id: 'p1',
      title: 'Order shipped',
      body: 'Your order ORD-7781 is on the way',
      source: 'FCM',
      kind: NotificationKind.received,
      time: _ago(80),
      payload: const {'orderId': 'ORD-7781', 'screen': 'order_detail'},
    ),
    NotificationEntry(
      id: 'p2',
      title: 'Promo 20% off',
      body: 'Limited time offer on tyres',
      source: 'FCM',
      kind: NotificationKind.tapped,
      time: _ago(300),
      payload: const {'screen': 'offers', 'campaign': 'tyres20'},
    ),
    NotificationEntry(
      id: 'p3',
      title: 'Reminder',
      body: 'Complete your KYC',
      source: 'local',
      kind: NotificationKind.received,
      time: _ago(520),
      payload: const {'screen': 'kyc'},
    ),
  ];

  static List<DeeplinkEntry> deeplinks() => [
    DeeplinkEntry(
      id: 'd1',
      uri: 'wheelseye://order/123?ref=push',
      source: 'push',
      time: _ago(78),
    ),
    DeeplinkEntry(
      id: 'd2',
      uri: 'https://wheelseye.com/offers?id=20&utm=email',
      source: 'browser',
      time: _ago(420),
    ),
    DeeplinkEntry(
      id: 'd3',
      uri: 'wheelseye://profile/settings',
      source: 'in-app',
      time: _ago(600),
    ),
  ];

  // SharedPreferences and database tables are no longer seeded here — the
  // Storage screen renders live prefs via `DebugLens.sharedPrefsSource` and
  // live databases via `DebugLens.registerDatabase` instead of mocks.

  static List<InfoSection> deviceInfo() => const [
    InfoSection(
      title: 'App',
      values: {
        'Name': 'DebugLens Demo',
        'Package': 'com.learning.example',
        'Version': '1.0.0',
        'Build': '1',
      },
    ),
    InfoSection(
      title: 'Device',
      values: {
        'Model': 'Pixel 7',
        'Manufacturer': 'Google',
        'OS': 'Android 14',
        'SDK': '34',
      },
    ),
    InfoSection(
      title: 'Screen',
      values: {
        'Resolution': '1080 x 2400',
        'Density': '2.625',
        'Orientation': 'portrait',
      },
    ),
    InfoSection(
      title: 'Runtime',
      values: {
        'Locale': 'en_US',
        'Timezone': 'Asia/Kolkata',
        'Memory (RSS)': '128 MB',
      },
    ),
  ];

  // Firebase data is no longer seeded here — the Firebase screen renders each
  // service's live data via `DebugLens.registerFirebaseService`.

  // Locale data is no longer seeded here — the Locale screen renders the app's
  // live strings via `DebugLens.localeSource` instead of any stored/mock copy.
}
