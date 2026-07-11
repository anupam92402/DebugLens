import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/material.dart';

/// A nested [Navigator] for one bottom-nav tab, observed by DebugLens.
///
/// Each tab gets its own labelled observer via
/// [DebugLens.newNavigatorObserver], so its pushes/pops are grouped under
/// [label] on the Navigation screen and it gets its own Stack entry.
class TabNavigator extends StatefulWidget {
  const TabNavigator({
    super.key,
    required this.navigatorKey,
    required this.label,
    required this.initialRoute,
    required this.onGenerateRoute,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final String label;
  final String initialRoute;
  final RouteFactory onGenerateRoute;

  @override
  State<TabNavigator> createState() => _TabNavigatorState();
}

class _TabNavigatorState extends State<TabNavigator> {
  late final DebugLensNavigatorObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = DebugLens.newNavigatorObserver(label: widget.label);
  }

  @override
  void dispose() {
    _observer.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.navigatorKey,
      observers: [_observer],
      initialRoute: widget.initialRoute,
      onGenerateRoute: widget.onGenerateRoute,
    );
  }
}
