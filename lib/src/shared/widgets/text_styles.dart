import 'package:flutter/material.dart';

import '../theme/debug_theme.dart';

String formatAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return '${d.inSeconds}s ago';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

TextStyle monoStyle({double size = 12, Color? color, FontWeight? weight}) =>
    TextStyle(
      fontFamily: DebugPalette.mono,
      fontSize: size,
      color: color ?? DebugPalette.textPrimary,
      fontWeight: weight,
    );
