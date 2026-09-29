import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:provider/provider.dart';

import '../core/debug_role.dart';
import '../features/walkthrough/data/walkthrough_store.dart';
import '../features/walkthrough/domain/walkthrough_step.dart';
import '../features/walkthrough/presentation/widgets/walkthrough_overlay.dart';
import '../shared/debug_strings.dart';
import 'debug_router.dart';
import 'debug_routes.dart';
import 'panel_bottom_bar.dart';
import 'panel_tab.dart';
import 'panel_tour_keys.dart';
import 'tab_usage_store.dart';
import '../shared/theme/debug_theme.dart';
import '../shared/widgets/glass_background.dart';
import '../shared/theme/debug_colors.dart';

/// Full-screen panel content: a self-contained nested [Navigator] driven by
/// named routes + [DebugRouter.onGenerateRoute], over the bottom bar that
/// switches between tabs. [onNestedChanged] fires whenever the nested stack
/// changes so the enclosing `DebugPanelRoute` can keep its back behaviour in
/// sync.
class DebugPanel extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback? onNestedChanged;

  const DebugPanel({
    super.key,
    required this.navigatorKey,
    this.onNestedChanged,
  });

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel>
    with SingleTickerProviderStateMixin {
  static const Duration _barSlide = Duration(milliseconds: 200);
  late final DebugRoleController _role;

  /// Root route of the open tab.
  late String _current;

  /// First-run tour targets. The role and close keys go null once the tour is
  /// done, so the root screens stop holding them.
  final GlobalKey _barKey = GlobalKey();
  GlobalKey? _roleKey = GlobalKey();
  GlobalKey? _closeKey = GlobalKey();

  /// The tour while it is on screen.
  OverlayEntry? _tour;

  /// Bar visibility: 1 shown, 0 slid away while scrolling down a list.
  late final AnimationController _bar = AnimationController(
    vsync: this,
    duration: _barSlide,
    value: 1,
  );
  bool _barHidden = false;

  late final _PanelNavObserver _navObserver = _PanelNavObserver(
    _onNestedChanged,
  );

  @override
  void initState() {
    super.initState();
    _role = context.read<DebugRoleController>();
    TabUsageStore.instance.startSession({
      for (final t in PanelTab.visibleTo(_role)) t.route,
    });
    _current = _firstRoute();
    _role.addListener(_onRoleChanged);
    TabUsageStore.instance.addListener(_onTabOrderChanged);
    // After the first frame, so the targets have been laid out and can be
    // measured.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
  }

  @override
  void dispose() {
    _removeTour();
    _role.removeListener(_onRoleChanged);
    TabUsageStore.instance.removeListener(_onTabOrderChanged);
    _bar.dispose();
    super.dispose();
  }

  /// A new screen starts with the bar shown.
  void _onNestedChanged() {
    widget.onNestedChanged?.call();
    _setBarHidden(false);
  }

  void _setBarHidden(bool hidden) {
    if (!mounted || hidden == _barHidden) return;
    setState(() => _barHidden = hidden);
    hidden ? _bar.reverse() : _bar.forward();
  }

  /// Scrolling a list down hides the bar; scrolling back up shows it.
  bool _onUserScroll(UserScrollNotification n) {
    if (n.metrics.axis == Axis.vertical) {
      switch (n.direction) {
        case ScrollDirection.reverse:
          _setBarHidden(true);
        case ScrollDirection.forward:
          _setBarHidden(false);
        case ScrollDirection.idle:
          break;
      }
    }
    return false;
  }

  /// A list that no longer scrolls can't bring the bar back, so it returns.
  bool _onScrollMetrics(ScrollMetricsNotification n) {
    if (n.metrics.axis == Axis.vertical && n.metrics.maxScrollExtent <= 0) {
      _setBarHidden(false);
    }
    return false;
  }

  PanelTabSplit _split() =>
      PanelTabSplit(PanelTab.visibleTo(_role), TabUsageStore.instance.slots);

  String _firstRoute() {
    final bar = _split().bar;
    return bar.isEmpty ? DebugRoutes.noAccess : bar.first.route;
  }

  /// A reset from Settings puts the default bar back straight away.
  void _onTabOrderChanged() {
    if (mounted) setState(() {});
  }

  /// A role swap or a changed grant can take the open tab away; move to the
  /// first tab still open to this role.
  void _onRoleChanged() {
    final open = PanelTab.visibleTo(_role).any((t) => t.route == _current);
    final next = _firstRoute();
    if (open || next == _current) {
      setState(() {});
      return;
    }
    _select(next, byUser: false);
  }

  /// Opens [route]'s tab at its root. Re-selecting the open tab pops back to
  /// its root instead of rebuilding it. [byUser] opens count towards the
  /// adaptive bar.
  void _select(String route, {bool byUser = true}) {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    if (route == _current) {
      navigator.popUntil((r) => r.isFirst);
      return;
    }
    if (byUser) TabUsageStore.instance.recordOpen(route);
    setState(() => _current = route);
    navigator.pushAndRemoveUntil(DebugRouter.tabRoute(route), (_) => false);
  }

  /// Shows the first-run tour once, over the host overlay so it can dim the
  /// app bar and the bottom bar.
  Future<void> _maybeShowTour() async {
    if (await WalkthroughStore.instance.hasSeen()) {
      _dropTourKeys();
      return;
    }
    if (!mounted || Overlay.maybeOf(context) == null) return;

    // Marked seen on show, not on finish: someone who closes the panel midway
    // has still seen it.
    await WalkthroughStore.instance.markSeen();
    if (!mounted) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (_) => WalkthroughOverlay(
        steps: [
          WalkthroughStep(
            title: DebugStrings.walkthroughPickTitle,
            body: DebugStrings.walkthroughPickBody,
            target: _barKey,
          ),
          WalkthroughStep(
            title: DebugStrings.walkthroughRoleTitle,
            body: DebugStrings.walkthroughRoleBody,
            target: _roleKey,
          ),
          WalkthroughStep(
            title: DebugStrings.walkthroughExploreTitle,
            body: DebugStrings.walkthroughExploreBody,
            target: _closeKey,
          ),
        ],
        onFinish: () {
          _removeTour();
          _dropTourKeys();
        },
      ),
    );
    _tour = entry;
    overlay.insert(entry);
  }

  /// Removes and disposes the tour, if shown.
  void _removeTour() {
    _tour
      ?..remove()
      ..dispose();
    _tour = null;
  }

  void _dropTourKeys() {
    if (!mounted) return;
    setState(() {
      _roleKey = null;
      _closeKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final split = _split();
    final showBar = split.bar.isNotEmpty;
    final media = MediaQuery.of(context);
    // Height the bar takes off the bottom, its safe area included.
    final barExtent = showBar
        ? media.padding.bottom + (_barHidden ? 0 : PanelBottomBar.height)
        : 0.0;

    return Theme(
      data: DebugTheme.build(DebugColors.base),
      child: Stack(
        children: [
          const Positioned.fill(child: GlassBackground()),
          Column(
            children: [
              Expanded(
                // Bottom insets less what the bar already covers.
                child: MediaQuery(
                  data: media.copyWith(
                    padding: media.padding.copyWith(bottom: showBar ? 0 : null),
                    viewPadding: media.viewPadding.copyWith(
                      bottom: showBar ? 0 : null,
                    ),
                    viewInsets: media.viewInsets.copyWith(
                      bottom: math.max(0, media.viewInsets.bottom - barExtent),
                    ),
                  ),
                  child: HeroControllerScope.none(
                    child: PanelTourKeys(
                      role: _roleKey,
                      close: _closeKey,
                      child: NotificationListener<ScrollMetricsNotification>(
                        onNotification: _onScrollMetrics,
                        child: NotificationListener<UserScrollNotification>(
                          onNotification: _onUserScroll,
                          child: Navigator(
                            key: widget.navigatorKey,
                            initialRoute: _current,
                            onGenerateRoute: DebugRouter.onGenerateRoute,
                            observers: [_navObserver],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (showBar)
                PanelBottomBar(
                  key: _barKey,
                  split: split,
                  current: _current,
                  visibility: _bar,
                  onSelect: _select,
                ),
            ],
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
