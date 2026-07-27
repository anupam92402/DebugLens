import 'package:flutter/material.dart';

import '../debug_constants.dart';

/// Opens [builder]'s widget as the panel's standard modal bottom sheet.
///
/// Every DebugLens sheet goes through here so they share one set of rules: a
/// transparent background (the sheets draw their own glass surface), scroll
/// control, and a height capped at
/// [DebugConstants.bottomSheetMaxHeightFraction] of the screen — past which a
/// long list scrolls inside the sheet rather than pushing it off the top.
Future<T?> showDebugBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight:
          MediaQuery.sizeOf(context).height *
          DebugConstants.bottomSheetMaxHeightFraction,
    ),
    builder: builder,
  );
}
