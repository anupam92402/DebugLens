import 'package:flutter/material.dart';

import '../../routing/debug_routes.dart';

/// Per-tool accent colors so each feature area has its own visual identity.
/// The router themes each screen with its route's accent; the dashboard tints
/// each tile with the same color.
class DebugAccents {
  DebugAccents._();

  static const base = Color(0xFF7C8CF8); // dashboard / fallback (indigo)
  static const network = Color(0xFF4F8CFF); // blue
  static const logs = Color(0xFF3FD17A); // green
  static const notifications = Color(0xFFFFC857); // amber
  static const navigation = Color(0xFFA78BFA); // violet
  static const bloc = Color(0xFFE11D48); // rose
  static const storage = Color(0xFF2DD4BF); // teal
  static const device = Color(0xFF22D3EE); // cyan
  static const firebase = Color(0xFFFB923C); // orange
  static const locale = Color(0xFFEC4899); // pink
  static const settings = Color(0xFF94A3B8); // slate

  static Color forRoute(String? route) {
    switch (route) {
      case DebugRoutes.network:
      case DebugRoutes.networkDetail:
      case DebugRoutes.networkHistory:
        return network;
      case DebugRoutes.logs:
      case DebugRoutes.logDetail:
        return logs;
      case DebugRoutes.notifications:
        return notifications;
      case DebugRoutes.navigation:
        return navigation;
      case DebugRoutes.bloc:
        return bloc;
      case DebugRoutes.storage:
        return storage;
      case DebugRoutes.device:
        return device;
      case DebugRoutes.firebase:
        return firebase;
      case DebugRoutes.locale:
        return locale;
      case DebugRoutes.settings:
        return settings;
      default:
        return base;
    }
  }
}
