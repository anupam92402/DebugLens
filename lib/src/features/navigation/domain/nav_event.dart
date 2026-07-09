enum NavAction { push, pop, replace, remove }

/// Classification of the Route involved — derived automatically from the
/// runtime type (PageRoute → page, DialogRoute → dialog, etc.).
enum NavRouteKind { page, dialog, sheet, popup, other }

class NavEvent {
  final int sequence;
  final NavAction action;
  final NavRouteKind kind;
  final String routeName;
  final String? previousRoute;
  final Object? arguments;
  final DateTime time;
  final String navigator;

  const NavEvent({
    required this.sequence,
    required this.action,
    required this.routeName,
    required this.time,
    this.kind = NavRouteKind.page,
    this.previousRoute,
    this.arguments,
    this.navigator = 'root',
  });

  String get actionLabel => action.name;
  String get kindLabel => kind.name;
}
