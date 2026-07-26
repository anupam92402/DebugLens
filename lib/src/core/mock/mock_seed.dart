import '../../features/device/domain/device_app_info.dart';

class MockSeed {
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
}
