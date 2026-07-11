import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/features/storage/data/debug_database_source.dart';
import 'src/features/firebase/data/debug_firebase_source.dart';
import 'src/shell/debug_lens_controller.dart';
import 'src/features/logs/data/debug_lens_logger.dart';
import 'src/features/locale/data/debug_locale_source.dart';
import 'src/core/debug_role.dart';
import 'src/features/storage/data/debug_shared_prefs_source.dart';
import 'src/core/debug_store.dart';
import 'src/features/navigation/data/debug_lens_navigator_observer.dart';
import 'src/shell/debug_bubble.dart';
import 'src/shell/debug_panel.dart';

export 'src/features/storage/data/debug_database_source.dart'
    show DebugLensDatabase;
export 'src/features/storage/domain/table_data.dart' show DebugLensTableData;
export 'src/features/firebase/data/debug_firebase_source.dart'
    show DebugLensFirebaseService;
export 'src/features/firebase/domain/info_group.dart' show DebugLensInfoGroup;
export 'src/features/logs/data/debug_lens_logger.dart' show DebugLensLogger;
export 'src/features/logs/domain/log_record.dart'
    show DebugLogLevel, DebugLogRecord, DebugLogSource;
export 'src/features/locale/data/debug_locale_source.dart'
    show DebugLensLocaleSource;
export 'src/features/locale/domain/locale_data.dart' show DebugLensLocaleData;
export 'src/features/storage/data/debug_shared_prefs_source.dart'
    show DebugLensSharedPrefsSource;
export 'src/features/storage/domain/pref_entry.dart' show DebugLensPrefEntry;
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
  static const String panelRouteName = 'debug_lens/panel';

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

  /// Registers a Firebase service for the Firebase screen. DebugLens calls its
  /// `load()` on demand and renders the returned info groups; it keeps no copy.
  /// Idempotent by [DebugLensFirebaseService.name]. DebugLens stays generic —
  /// it never imports any Firebase package.
  static void registerFirebaseService(DebugLensFirebaseService service) =>
      DebugLensFirebase.register(service);

  /// The registered Firebase services shown on the Firebase screen.
  static List<DebugLensFirebaseService> get firebaseServices =>
      DebugLensFirebase.services;

  /// Wraps [child] (use from `MaterialApp.builder`) to provide the DebugLens
  /// state and overlay a draggable bubble. Tapping the bubble opens the panel.
  ///
  /// Also installs a `debugPrint` override on first call so framework prints
  /// and `debugPrint(...)` calls are captured into the Logs screen with
  /// `DebugLogSource.console`. Raw `print(...)` is not captured by default —
  /// wrap your `main()` in [runZoned] for full coverage.
  static Widget wrap(Widget child) {
    _installConsoleCapture();
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

  /// Opt-in wrapper that captures raw `print(...)` calls and uncaught zone
  /// errors into the Logs screen. Use it around your app's entry point when
  /// you want full console capture:
  ///
  /// ```dart
  /// void main() {
  ///   DebugLens.runZoned(() => runApp(const MyApp()));
  /// }
  /// ```
  ///
  /// The `debugPrint` override installed by [wrap] is independent — this is
  /// only needed for raw `print()` and zone-unhandled errors.
  static T? runZoned<T>(T Function() body) {
    return runZonedGuarded<T>(
      body,
      (error, stack) {
        DebugLensLogger.instance.e(
          'Uncaught zone error',
          name: 'zone',
          error: error,
          stackTrace: stack,
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          DebugLensLogger.instance.recordConsole(line);
          parent.print(zone, line);
        },
      ),
    );
  }

  // --- Console capture wiring ---------------------------------------------

  static bool _consoleCaptureInstalled = false;

  static void _installConsoleCapture() {
    if (_consoleCaptureInstalled) return;
    _consoleCaptureInstalled = true;
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        DebugLensLogger.instance.recordConsole(message);
      }
      original(message, wrapWidth: wrapWidth);
    };
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
