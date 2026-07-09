// All NavigatorObserver methods are overridden intentionally for completeness;
// the gesture callbacks simply delegate to super.
// ignore_for_file: unnecessary_overrides
import 'package:flutter/material.dart';

import '../core/debug_lens_logger.dart';
import '../core/debug_store.dart';
import '../core/models/nav_event.dart';

// DebugLens's own panel route is pushed on the host navigator with the name
// `DebugLens.panelRouteName`, so it appears on the Navigation screen with a
// readable label rather than as an anonymous `PageRouteBuilder`.

/// A [NavigatorObserver] that records every route transition into the shared
/// [DebugStore] (Events tab) and keeps a live snapshot of the current route
/// stack (Stack tab). Add it to `MaterialApp.navigatorObservers`:
///
/// ```dart
/// MaterialApp(navigatorObservers: [DebugLens.navigatorObserver]);
/// ```
class DebugLensNavigatorObserver extends NavigatorObserver {
  DebugLensNavigatorObserver({DebugStore? store, this.label = 'root'})
    : _store = store ?? DebugStore.instance;

  final DebugStore _store;

  /// Identifies the navigator this observer is attached to (groups its events
  /// and gives it its own Stack entry; pass a unique label per nested navigator).
  final String label;

  /// Live route stack (bottom → top), tracked by Route identity.
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];

  /// Call when the observed navigator is disposed to drop its stack snapshot.
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
    // Also surface in the Logs screen so developers see navigation alongside
    // their own logs. Logged at debug level — easy to filter out when noisy.
    DebugLensLogger().d(
      _formatNavMessage(action, routeName, previousName),
      name: 'nav.$label',
    );
  }

  /// Compact one-liner for the Logs feed — e.g. `push: /splash → /home`.
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

  /// Maps the runtime Route type to a NavRouteKind. Order matters because
  /// DialogRoute and ModalBottomSheetRoute both extend PopupRoute.
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

  // Gesture callbacks fire mid-interaction, so they're not recorded as
  // discrete events — overridden here only for completeness.
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
