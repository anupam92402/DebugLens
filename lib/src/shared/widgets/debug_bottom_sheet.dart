import 'package:flutter/material.dart';

import '../debug_constants.dart';

/// Opens [builder]'s widget as the panel's standard modal bottom sheet.
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
