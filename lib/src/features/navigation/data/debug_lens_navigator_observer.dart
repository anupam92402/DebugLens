import 'package:flutter/material.dart';

import '../../logs/data/debug_lens_logger.dart';
import '../../../core/debug_store.dart';
import '../domain/nav_event.dart';

/// Records route transitions into DebugStore and keeps a live stack snapshot.
/// Add to MaterialApp.navigatorObservers.
class DebugLensNavigatorObserver extends NavigatorObserver {
  DebugLensNavigatorObserver({DebugStore? store, this.label = 'root'})
    : _store = store ?? DebugStore.instance;

  final DebugStore _store;

  /// Identifies the navigator; unique per nested navigator.
  final String label;

  /// Live route stack (bottom to top).
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];

  /// Drops this navigator's stack snapshot when it's disposed.
  void detach() => _store.removeNavStack(label);

  String _nameOf(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name.isNotEmpty) return name;
    if (route == null) return 'unknown';
    return route.runtimeType.toString();
  }

  void _record(
    NavAction action,
    Route<dynamic>? route,
    Route<dynamic>? previous,
  ) {
    final routeName = _nameOf(route);
    final previousName = previous == null ? null : _nameOf(previous);
    _store.recordNavigation(
      action: action,
      routeName: routeName,
      previousRoute: previousName,
      arguments: route?.settings.arguments,
      navigator: label,
      kind: _kindOf(route),
    );
    /// Also surface in the Logs feed (debug level).
    DebugLensLogger().d(
      _formatNavMessage(action, routeName, previousName),
      name: 'nav.$label',
    );
  }

  /// Compact one-liner for the Logs feed.
  String _formatNavMessage(
    NavAction action,
    String routeName,
    String? previousName,
  ) {
    switch (action) {
      case NavAction.push:
        return previousName == null
            ? 'push: $routeName'
            : 'push: $previousName → $routeName';
      case NavAction.pop:
        return previousName == null
            ? 'pop: $routeName'
            : 'pop: $routeName → $previousName';
      case NavAction.replace:
        return previousName == null
            ? 'replace: $routeName'
            : 'replace: $previousName → $routeName';
      case NavAction.remove:
        return 'remove: $routeName';
    }
  }

  /// Maps route type to a kind. Order matters: Dialog/Sheet extend PopupRoute.
  NavRouteKind _kindOf(Route<dynamic>? route) {
    if (route == null) return NavRouteKind.other;
    if (route is PageRoute) return NavRouteKind.page;
    if (route is DialogRoute) return NavRouteKind.dialog;
    if (route is ModalBottomSheetRoute) return NavRouteKind.sheet;
    if (route is PopupRoute) return NavRouteKind.popup;
    return NavRouteKind.other;
  }

  void _syncStack() {
    _store.setNavStack(label, [for (final r in _stack) _nameOf(r)]);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _stack.add(route);
    _record(NavAction.push, route, previousRoute);
    _syncStack();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _stack.remove(route);
    _record(NavAction.pop, route, previousRoute);
    _syncStack();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
      if (index >= 0) {
        _stack[index] = newRoute;
      } else {
        _stack.add(newRoute);
      }
    }
    _record(NavAction.replace, newRoute, oldRoute);
    _syncStack();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _stack.remove(route);
    _record(NavAction.remove, route, previousRoute);
    _syncStack();
  }

  /// Gesture callbacks aren't recorded; overridden for completeness.
  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    super.didStartUserGesture(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    super.didStopUserGesture();
  }
}
