import 'package:flutter/widgets.dart';

/// Owns the open/closed state of the DebugLens panel.
///
/// The panel is shown as a real route pushed on the host navigator (so the
/// system back button — including Android predictive back — closes it). This
/// controller just tracks that route so the bubble can hide while open and the
/// in-panel close button can dismiss it.
class DebugLensController extends ChangeNotifier {
  /// Key for the panel's nested [Navigator] so back can pop in-panel routes
  /// (step back) before closing the whole panel.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Route<dynamic>? _panelRoute;

  /// True while the panel route is on the host navigator.
  bool get isOpen => _panelRoute != null;

  /// Records the pushed panel route (call right before/while pushing).
  void attachRoute(Route<dynamic> route) {
    _panelRoute = route;
    notifyListeners();
  }

  /// Clears the recorded route (call when the route has been popped).
  void detachRoute() {
    if (_panelRoute == null) return;
    _panelRoute = null;
    notifyListeners();
  }

  /// Closes the panel by popping its route off the host navigator. Used by the
  /// in-panel close button; the system back button is handled by the route's
  /// `PopScope`.
  void close() => _panelRoute?.navigator?.pop();
}
