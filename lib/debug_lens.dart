import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/features/storage/data/debug_database_source.dart';
import 'src/features/services/data/debug_service_source.dart';
import 'src/shell/debug_lens_controller.dart';
import 'src/shell/debug_routes.dart';
import 'src/features/logs/data/debug_lens_logger.dart';
import 'src/features/locale/data/debug_locale_source.dart';
import 'src/core/debug_role.dart';
import 'src/features/storage/data/debug_shared_prefs_source.dart';
import 'src/core/debug_store.dart';
import 'src/features/notifications/domain/notification_entry.dart';
import 'src/features/notifications/domain/deeplink_entry.dart';
import 'src/features/navigation/data/debug_lens_navigator_observer.dart';
import 'src/shell/debug_bubble.dart';
import 'src/shell/debug_panel.dart';

export 'src/features/storage/data/debug_database_source.dart'
    show DebugLensDatabase;
export 'src/features/storage/domain/table_data.dart' show DebugLensTableData;
export 'src/features/services/data/debug_service_source.dart'
    show DebugLensService;
export 'src/features/services/domain/service_group.dart'
    show DebugLensServiceGroup;
export 'src/features/services/domain/config_editor.dart'
    show DebugLensConfigEditor, DebugLensConfigEntry, DebugLensConfigType;
export 'src/features/logs/data/debug_lens_logger.dart'
    show DebugLensLogger, DebugLogObserver;
export 'src/features/logs/domain/log_origin.dart' show DebugLogOrigin;
export 'src/features/logs/domain/log_record.dart'
    show DebugLogLevel, DebugLogRecord;
export 'src/features/locale/data/debug_locale_source.dart'
    show DebugLensLocaleSource;
export 'src/features/locale/domain/locale_data.dart' show DebugLensLocaleData;
export 'src/features/storage/data/debug_shared_prefs_source.dart'
    show DebugLensSharedPrefsSource;
export 'src/features/storage/domain/pref_entry.dart'
    show DebugLensPrefEntry, DebugLensPrefType;
export 'src/core/debug_log_file_service.dart' show DebugLogFileService;
export 'src/features/bloc/data/debug_lens_bloc_observer.dart'
    show DebugLensBlocObserver;
export 'src/features/network/data/debug_lens_dio_interceptor.dart'
    show DebugLensDioInterceptor, DebugLensDioInterceptorSettings;
export 'src/features/navigation/data/debug_lens_navigator_observer.dart'
    show DebugLensNavigatorObserver;

/// Public entry point for the DebugLens in-app debugging overlay.
class DebugLens {
  DebugLens._();

  /// Route name given to DebugLens's own panel route on the host navigator, so
  /// it shows a readable label (instead of `PageRouteBuilder`) on the
  /// Navigation screen.
  static const String panelRouteName = DebugRoutes.panelRouteName;

  /// Add to your `MaterialApp.navigatorObservers` to capture navigation events.
  static final NavigatorObserver navigatorObserver =
      DebugLensNavigatorObserver();

  /// Creates an additional observer for a nested [Navigator]. All observers
  /// write to the same store; pass a unique [label] to identify the navigator
  /// (its events are grouped under that label and it gets its own Stack entry).
  /// Call `detach()` when the nested navigator is disposed.
  static DebugLensNavigatorObserver newNavigatorObserver({
    required String label,
  }) => DebugLensNavigatorObserver(label: label);

  /// Registers a pull-based source for the Locale screen. DebugLens calls this
  /// each time the screen builds and renders the result — it stores no copy of
  /// the locale data. Set from the host once the app's lang map is available;
  /// pass `null` to clear. Works the same whether the data was loaded from
  /// network or local cache (the source shape is identical).
  static set localeSource(DebugLensLocaleSource? source) =>
      DebugLensLocale.source = source;

  static DebugLensLocaleSource? get localeSource => DebugLensLocale.source;

  /// Registers a pull-based source for the Storage screen's SharedPrefs tab.
  /// DebugLens calls this each time the screen builds and renders the result —
  /// it stores no copy. Set from the host's SharedPreferences wrapper; pass
  /// `null` to clear. DebugLens stays generic and never imports the client.
  static set sharedPrefsSource(DebugLensSharedPrefsSource? source) =>
      DebugLensSharedPrefs.source = source;

  static DebugLensSharedPrefsSource? get sharedPrefsSource =>
      DebugLensSharedPrefs.source;

  /// Registers a database for the Storage screen's Database tab. DebugLens
  /// reads tables/rows from it on demand and keeps no copy. Idempotent by
  /// [DebugLensDatabase.name]. DebugLens stays generic — it never imports the
  /// client's database package.
  static void registerDatabase(DebugLensDatabase database) =>
      DebugLensDatabases.register(database);

  /// The registered databases shown in the Database tab.
  static List<DebugLensDatabase> get databases => DebugLensDatabases.sources;

  /// Registers a backend/SDK service for the Services screen (Firebase
  /// Analytics, Remote Config, LaunchDarkly, your own API client, …). DebugLens
  /// calls its `load()` on demand and renders the returned groups; it keeps no
  /// copy. Idempotent by [DebugLensService.name]. DebugLens stays generic — it
  /// never imports any vendor package.
  static void registerService(DebugLensService service) =>
      DebugLensServices.register(service);

  /// The registered services shown on the Services screen.
  static List<DebugLensService> get services => DebugLensServices.services;

  /// Records a push/local notification on the Notifications screen. Call from
  /// your notification handler on both display and tap ([tapped] `true` for a
  /// tap). DebugLens generates the id and timestamp. [payload] is the raw data
  /// map; [source] labels the origin (e.g. `FCM`, `local`).
  static void recordNotification({
    String? title,
    String? body,
    Map<String, Object?> payload = const {},
    String source = 'FCM',
    bool tapped = false,
  }) {
    DebugStore.instance.recordNotification(
      NotificationEntry(
        id: _nextRecordId('ntf'),
        time: DateTime.now(),
        title: title,
        body: body,
        payload: DebugStore.snapshotPayload(payload),
        source: source,
        kind: tapped ? NotificationKind.tapped : NotificationKind.received,
      ),
    );
  }

  /// Clears the captured notifications shown on the Notifications tab.
  static void clearNotifications() => DebugStore.instance.clearNotifications();

  /// Clears the captured deep-links shown on the Deep-links tab.
  static void clearDeeplinks() => DebugStore.instance.clearDeeplinks();

  /// Records a captured deep-link on the Notifications screen's Deep-links tab.
  /// Call from your deep-link/app-links handler. DebugLens generates the id and
  /// timestamp; [source] labels the origin (e.g. `push`, `browser`, `in-app`).
  static void recordDeeplink(String uri, {String? source}) {
    DebugStore.instance.recordDeeplink(
      DeeplinkEntry(
        id: _nextRecordId('dl'),
        uri: uri,
        time: DateTime.now(),
        source: source,
      ),
    );
  }

  /// Monotonic id suffix so entries recorded within the same millisecond stay
  /// unique (mirrors the dio interceptor's id scheme).
  static int _recordSeq = 0;

  static String _nextRecordId(String prefix) {
    _recordSeq++;
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$_recordSeq';
  }

  /// Wraps [child] (use from `MaterialApp.builder`) to provide the DebugLens
  /// state and overlay a draggable bubble. Tapping the bubble opens the panel.
  static Widget wrap(Widget child) {
    /// Restoring the Logs capture switches reads SharedPreferences, which needs
    /// the binding — safe here, since [wrap] runs once the tree is up.
    DebugLensLogger.instance.restoreCaptureSettings();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DebugLensController()),
        ChangeNotifierProvider(create: (_) => DebugRoleController()),
        ChangeNotifierProvider<DebugStore>.value(value: DebugStore.instance),
        ChangeNotifierProvider<DebugLensLogger>.value(
          value: DebugLensLogger.instance,
        ),
      ],
      child: _DebugLensHost(child: child),
    );
  }

  /// Opens the panel. It is pushed as a route on the host navigator (the one
  /// [navigatorObserver] is attached to) so the system back button — including
  /// Android predictive back — closes it. No-op if already open or if the host
  /// navigator isn't available yet. [context] must be below [wrap].
  static void show(BuildContext context) {
    final controller = context.read<DebugLensController>();
    if (controller.isOpen) return;
    final navigator = navigatorObserver.navigator;
    if (navigator == null) return;
    final route = PageRouteBuilder<void>(
      settings: const RouteSettings(name: panelRouteName),
      // Non-opaque so the live app stays visible (blurred) behind the glass,
      // matching the previous overlay look.
      opaque: false,
      pageBuilder: (_, __, ___) =>
          DebugPanelRoute(navigatorKey: controller.navigatorKey),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
    controller.attachRoute(route);
    navigator.push(route).whenComplete(controller.detachRoute);
  }
}

class _DebugLensHost extends StatefulWidget {
  final Widget child;

  const _DebugLensHost({required this.child});

  @override
  State<_DebugLensHost> createState() => _DebugLensHostState();
}

class _DebugLensHostState extends State<_DebugLensHost> {
  // Back handling now lives in the panel route's `PopScope` (see DebugPanel),
  // which works with Android predictive back — no WidgetsBindingObserver needed.

  @override
  Widget build(BuildContext context) {
    // Hide the bubble while the panel route is open; the panel covers the app.
    final isOpen = context.watch<DebugLensController>().isOpen;
    return Stack(
      children: [
        widget.child,
        if (!isOpen)
          Positioned.fill(
            child: DebugBubble(onTap: () => DebugLens.show(context)),
          ),
      ],
    );
  }
}
