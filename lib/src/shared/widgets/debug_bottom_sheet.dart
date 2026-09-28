import 'package:flutter/material.dart';

import '../debug_constants.dart';

/// Opens [builder]'s widget as the panel's standard modal bottom sheet, under
/// [name] — a `debug_lens/sheet_` route from `DebugRoutes`, so the Navigation
/// screen shows which sheet it was and can hide it.
Future<T?> showDebugBottomSheet<T>(
  BuildContext context, {
  required String name,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    routeSettings: RouteSettings(name: name),
    constraints: BoxConstraints(
      maxHeight:
          MediaQuery.sizeOf(context).height *
          DebugConstants.bottomSheetMaxHeightFraction,
    ),
    builder: builder,
  );
}
