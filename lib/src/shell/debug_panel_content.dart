import 'package:flutter/material.dart';

import 'debug_router.dart';
import 'debug_routes.dart';
import '../shared/theme/debug_accents.dart';
import '../shared/theme/debug_theme.dart';
import '../shared/widgets/glass.dart';

/// Full-screen panel content. Hosts a self-contained nested [Navigator] driven
/// by named routes + [DebugRouter.onGenerateRoute]. [onNestedChanged] fires
/// whenever the nested stack changes so the enclosing `DebugPanelRoute` can
/// keep its back behaviour in sync.
class DebugPanel extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback? onNestedChanged;

  const DebugPanel({
    super.key,
    required this.navigatorKey,
    this.onNestedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DebugTheme.build(DebugAccents.base),
      child: Stack(
        children: [
          const Positioned.fill(child: GlassBackground()),
          HeroControllerScope.none(
            child: Navigator(
              key: navigatorKey,
              initialRoute: DebugRoutes.dashboard,
              onGenerateRoute: DebugRouter.onGenerateRoute,
              observers: [_PanelNavObserver(onNestedChanged)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Notifies [onChanged] (after the frame, so reads of `canPop()` are accurate)
/// whenever the panel's nested navigator stack changes.
class _PanelNavObserver extends NavigatorObserver {
  final VoidCallback? onChanged;

  _PanelNavObserver(this.onChanged);

  void _notify() {
    final cb = onChanged;
    if (cb == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => cb());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _notify();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _notify();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _notify();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _notify();
  }
}
