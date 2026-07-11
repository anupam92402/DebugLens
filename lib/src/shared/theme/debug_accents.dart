import 'package:flutter/material.dart';

import '../../shell/debug_routes.dart';
import 'debug_colors.dart';

/// Maps a route to its per-tool accent color — the router themes each screen
/// with its route's accent and the dashboard tints each tile the same. Colors
/// live in [DebugColors].
class DebugAccents {
  DebugAccents._();

  static Color forRoute(String? route) {
    switch (route) {
      case DebugRoutes.network:
      case DebugRoutes.networkDetail:
      case DebugRoutes.networkHistory:
        return DebugColors.network;
      case DebugRoutes.logs:
      case DebugRoutes.logDetail:
        return DebugColors.logs;
      case DebugRoutes.notifications:
        return DebugColors.notifications;
      case DebugRoutes.navigation:
        return DebugColors.navigation;
      case DebugRoutes.bloc:
        return DebugColors.bloc;
      case DebugRoutes.storage:
        return DebugColors.storage;
      case DebugRoutes.device:
        return DebugColors.device;
      case DebugRoutes.firebase:
        return DebugColors.firebase;
      case DebugRoutes.locale:
        return DebugColors.locale;
      case DebugRoutes.settings:
        return DebugColors.settings;
      default:
        return DebugColors.base;
    }
  }
}
