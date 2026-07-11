/// The kind of route transition an observer reported.
enum NavAction { push, pop, replace, remove }

/// Route kind, derived from the route's runtime type.
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
