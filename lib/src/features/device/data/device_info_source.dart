import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../shared/util/connectivity_label.dart';
import '../domain/device_app_info.dart';

/// Gathers the device and app facts shown on the Device screen.
class DeviceInfoSource {
  DeviceInfoSource._();

  static List<InfoSection>? _cache;

  /// App + Device — the two platform-channel sections, read once per run.
  static Future<List<InfoSection>> platform() async {
    final cached = _cache;
    if (cached != null) return cached;

    final (app, appOk) = await _read(_appValues);
    final (device, deviceOk) = await _read(_deviceValues);

    final sections = [
      InfoSection(title: 'App', values: app),
      InfoSection(title: 'Device', values: device),
    ];
    if (appOk && deviceOk) _cache = sections;
    return sections;
  }

  /// Runs [reader], reporting a failure as a visible row rather than a missing
  /// section — a debugging tool that quietly hides its own breakage is worse
  /// than one that shows the exception.
  static Future<(Map<String, String>, bool)> _read(
    Future<Map<String, String>> Function() reader,
  ) async {
    try {
      return (await reader(), true);
    } catch (error) {
      return ({'Unavailable': '$error'}, false);
    }
  }

  static Future<Map<String, String>> _appValues() async {
    final package = await PackageInfo.fromPlatform();
    return {
      'Name': package.appName,
      'Package': package.packageName,
      'Version': package.version,
      'Build': package.buildNumber,
    };
  }

  static Future<Map<String, String>> _deviceValues() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await plugin.androidInfo;
      return {
        'Model': android.model,
        'Manufacturer': android.manufacturer,
        'OS': 'Android ${android.version.release}',
        'SDK': '${android.version.sdkInt}',
        'Physical': '${android.isPhysicalDevice}',
      };
    }
    if (Platform.isIOS) {
      final ios = await plugin.iosInfo;
      return {
        'Model': ios.utsname.machine,
        'Name': ios.name,
        'OS': '${ios.systemName} ${ios.systemVersion}',
        'Physical': '${ios.isPhysicalDevice}',
      };
    }
    // Desktop: no curated shape, so surface whatever the plugin reports.
    final info = await plugin.deviceInfo;
    return {for (final e in info.data.entries) e.key: '${e.value}'};
  }

  /// The active transport, from the latest `connectivityStream` value. Reports
  /// what the device is attached to, not whether anything is reachable over it
  /// — a captive-portal wifi still reads `Wi-Fi`.
  static InfoSection network(ConnectivityResult? result) => InfoSection(
    title: 'Network',
    values: {'Type': connectivityLabel(result)},
  );

  /// Live screen metrics — recomputed by the caller on every build, so a
  /// rotation swaps the dimensions and updates `Orientation` immediately.
  static InfoSection screen(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final ratio = media.devicePixelRatio;
    return InfoSection(
      title: 'Screen',
      values: {
        'Resolution':
            '${(size.width * ratio).round()} x ${(size.height * ratio).round()}',
        'Logical': '${size.width.round()} x ${size.height.round()}',
        'Density': ratio.toStringAsFixed(3),
        'Orientation': media.orientation.name,
        'Text scale': media.textScaler.scale(1).toStringAsFixed(2),
        'Locale': Platform.localeName,
      },
    );
  }
}
