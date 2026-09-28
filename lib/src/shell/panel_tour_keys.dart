import 'package:flutter/widgets.dart';

/// Keys the first-run tour measures inside the root screen's app bar. Null
/// once the tour is done, so no screen holds them afterwards.
class PanelTourKeys extends InheritedWidget {
  final GlobalKey? role;
  final GlobalKey? close;

  const PanelTourKeys({
    super.key,
    required this.role,
    required this.close,
    required super.child,
  });

  static PanelTourKeys? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PanelTourKeys>();

  @override
  bool updateShouldNotify(PanelTourKeys oldWidget) =>
      role != oldWidget.role || close != oldWidget.close;
}
