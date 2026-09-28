import 'package:flutter/material.dart';

/// Opens [builder]'s widget as a panel dialog, under [name] — a
/// `debug_lens/dialog_` route from `DebugRoutes`, so the Navigation screen
/// shows which dialog it was and can hide it.
Future<T?> showDebugDialog<T>(
  BuildContext context, {
  required String name,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    routeSettings: RouteSettings(name: name),
    builder: builder,
  );
}
