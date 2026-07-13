import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../data/notification_log_share.dart';
import '../widgets/deeplinks_tab.dart';
import '../widgets/notifications_tab.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Two-tab view of push/local notifications + captured deep-links.
/// Thin assembler — both tab bodies live in `widgets/` and own their
/// search/sort state. The AppBar's clear action targets the active tab.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  /// Clears whichever tab is currently active.
  void _clearActive() {
    final store = context.read<DebugStore>();
    if (_tab.index == 0) {
      store.clearNotifications();
      DebugToast.show(context, DebugStrings.notificationsClearedToast);
    } else {
      store.clearDeeplinks();
      DebugToast.show(context, DebugStrings.deeplinksClearedToast);
    }
  }

  /// Shares whichever tab is currently active as a log file.
  void _shareActive() {
    final store = context.read<DebugStore>();
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    if (_tab.index == 0) {
      NotificationLogShare.shareNotifications(store, origin: origin);
    } else {
      NotificationLogShare.shareDeeplinks(store, origin: origin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final store = context.watch<DebugStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(DebugStrings.notificationsTitle),
        actions: [
          ListenableBuilder(
            listenable: _tab,
            builder: (_, _) => IconButton(
              tooltip: _tab.index == 0
                  ? DebugStrings.notificationsShareTooltip
                  : DebugStrings.deeplinksShareTooltip,
              icon: const Icon(Icons.share),
              onPressed: _shareActive,
            ),
          ),
          ListenableBuilder(
            listenable: _tab,
            builder: (_, _) => IconButton(
              tooltip: _tab.index == 0
                  ? DebugStrings.notificationsClearTooltip
                  : DebugStrings.deeplinksClearTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearActive,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: accent,
          indicatorColor: accent,
          unselectedLabelColor: DebugColors.textMuted,
          tabs: [
            Tab(
              text:
                  '${DebugStrings.notificationsTabNotifications} '
                  '(${store.notifications.length})',
            ),
            Tab(
              text:
                  '${DebugStrings.notificationsTabDeeplinks} '
                  '(${store.deeplinks.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          NotificationsTab(items: store.notifications),
          DeeplinksTab(items: store.deeplinks),
        ],
      ),
    );
  }
}
