import 'package:flutter/material.dart';

import 'debug_panel_content.dart';

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
