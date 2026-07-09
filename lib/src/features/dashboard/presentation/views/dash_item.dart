import 'package:flutter/material.dart';

import '../../../../shared/theme/debug_accents.dart';

/// A single dashboard tile's data: icon, title, and the route it opens.
class DashItem {
  final IconData icon;
  final String title;
  final String route;

  const DashItem(this.icon, this.title, this.route);

  Color get color => DebugAccents.forRoute(route);
}
