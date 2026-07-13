import 'package:flutter/widgets.dart';

/// Root navigator key, so code outside the widget tree (e.g. a notification
/// tap handler) can push routes.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
