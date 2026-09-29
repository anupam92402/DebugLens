import 'package:flutter/material.dart';

import '../theme/debug_colors.dart';

TextStyle monoStyle({double size = 12, Color? color, FontWeight? weight}) =>
    TextStyle(
      fontFamily: DebugColors.mono,
      fontSize: size,
      color: color ?? DebugColors.textPrimary,
      fontWeight: weight,
    );
