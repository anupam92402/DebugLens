import 'package:flutter/material.dart';

import '../routing/debug_router.dart';
import '../routing/debug_routes.dart';
import 'theme/debug_accents.dart';
import 'theme/debug_theme.dart';
import 'widgets/glass.dart';

/// The panel as a host-navigator route. A [PopScope] makes the system back
/// button (including Android predictive back) step back through in-panel routes
/// first, then close the panel itself once the nested navigator is at its root.
class DebugPanelRoute extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const DebugPanelRoute({super.key, required this.navigatorKey});

  @override
  State<DebugPanelRoute> createState() => _DebugPanelRouteState();
}

class _DebugPanelRouteState extends State<DebugPanelRoute> {
  bool _nestedCanPop = false;

  void _refreshCanPop() {
    final canPop = widget.navigatorKey.currentState?.canPop() ?? false;
    if (canPop != _nestedCanPop && mounted) {
      setState(() => _nestedCanPop = canPop);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // When the nested navigator can pop, intercept back and pop it; otherwise
      // allow the pop so this route (the whole panel) closes.
      canPop: !_nestedCanPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        widget.navigatorKey.currentState?.maybePop();
      },
      child: DebugPanel(
        navigatorKey: widget.navigatorKey,
        onNestedChanged: _refreshCanPop,
      ),
    );
  }
}

/// Full-screen panel content. Hosts a self-contained nested [Navigator] driven
/// by named routes + [DebugRouter.onGenerateRoute]. [onNestedChanged] fires
/// whenever the nested stack changes so the enclosing [DebugPanelRoute] can
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
