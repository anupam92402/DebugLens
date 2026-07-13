import 'dart:convert';

import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_navigator.dart';
import '../firebase/mock_firebase.dart';
import '../../features/notifications/presentation/views/notification_landing_screen.dart';

/// Shows on-device local notifications (no Firebase / backend). Used to
/// demonstrate the app raising notifications; call [triggerSamples] to fire a
/// batch.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'debug_lens_demo';
  static const String _channelName = 'Demo notifications';

  /// A few varied sample notifications (title, body, payload).
  static const List<(String, String, Map<String, Object?>)> _samples = [
    (
      'Order shipped',
      'Your order #7781 is on the way.',
      {'route': '/orders/7781'},
    ),
    (
      'Weekly report',
      'Your insights for last week are ready.',
      {'route': '/insights'},
    ),
    (
      'Payment due',
      'Electricity bill of ₹2,340 is due tomorrow.',
      {'route': '/bills/9921'},
    ),
    (
      'New follower',
      '@debuglens started following you.',
      {'route': '/profile'},
    ),
    (
      'Backup complete',
      'Your data was backed up successfully.',
      <String, Object?>{},
    ),
    (
      'Weekend offer',
      '20% off your next order — today only!',
      {'route': '/promo'},
    ),
  ];

  /// How many samples a trigger will actually fire — capped by the mock
  /// Remote Config `notification_batch_size` flag (feature-flagged batch size).
  int get sampleCount {
    final cap = MockFirebase.remoteConfig.getInt('notification_batch_size');
    return cap > 0 && cap < _samples.length ? cap : _samples.length;
  }

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  /// On tap, deep-link to the landing screen using the notification's payload.
  void _onTap(NotificationResponse response) {
    final raw = response.payload;
    var data = <String, dynamic>{};
    if (raw != null && raw.isNotEmpty) {
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        // Non-JSON payload — nothing to route on.
      }
    }
    // Surface the tap in DebugLens, plus the route it deep-links to.
    DebugLens.recordNotification(
      title: data['title'] as String?,
      body: data['body'] as String?,
      payload: data,
      source: 'local',
      tapped: true,
    );
    final route = data['route'];
    if (route is String && route.isNotEmpty) {
      DebugLens.recordDeeplink(route, source: 'notification');
    }
    appNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'notification-landing'),
        builder: (_) => NotificationLandingScreen(data: data),
      ),
    );
  }

  /// Fires the first [sampleCount] samples as immediate notifications, timed as
  /// a mock-Firebase performance trace.
  Future<void> triggerSamples() async {
    await init();
    final count = sampleCount;
    final trace = MockFirebase.performance.newTrace('notifications_dispatch')
      ..putAttribute('batch', '$count')
      ..start();
    MockFirebase.analytics.logEvent(
      'test_notifications_sent',
      parameters: {'count': count},
    );
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    for (var i = 0; i < count; i++) {
      final (title, body, payload) = _samples[i];
      // Carry title/body in the payload too, so the tap landing screen can
      // show them without another lookup.
      await _plugin.show(
        i,
        title,
        body,
        details,
        payload: jsonEncode({'title': title, 'body': body, ...payload}),
      );
      // Mirror the shown notification into DebugLens's Notifications inspector.
      DebugLens.recordNotification(
        title: title,
        body: body,
        payload: payload,
        source: 'local',
      );
    }
    trace.stop();
  }
}
