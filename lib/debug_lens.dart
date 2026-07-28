import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/features/storage/data/debug_database_source.dart';
import 'src/shared/debug_constants.dart';
import 'src/shared/debug_strings.dart';
import 'src/features/dashboard/data/dash_order_store.dart';
import 'src/features/services/data/debug_analytics_store.dart';
import 'src/features/settings/data/app_version_store.dart';
import 'src/features/settings/data/bubble_store.dart';
import 'src/features/settings/data/debug_limits_store.dart';
import 'src/features/services/data/debug_config_store.dart';
import 'src/features/services/data/debug_crash_store.dart';
import 'src/features/services/data/debug_service_source.dart';
import 'src/features/services/data/debug_trace_store.dart';
import 'src/features/services/domain/analytics_event.dart';
import 'src/features/services/domain/crash_event.dart';
import 'src/features/services/domain/trace_event.dart';
import 'src/shell/debug_lens_controller.dart';
import 'src/shell/debug_routes.dart';
import 'src/features/logs/data/debug_lens_logger.dart';
import 'src/features/locale/data/debug_locale_source.dart';
import 'src/core/debug_lens_config.dart';
import 'src/core/debug_role.dart';
import 'src/core/debug_screen.dart';
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
export 'src/features/services/domain/crash_event.dart' show DebugLensCrashEvent;
export 'src/features/error/presentation/views/custom_error_screen.dart'
    show CustomErrorScreen;
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
export 'src/core/debug_role.dart' show DebugRole;
export 'src/core/debug_screen.dart' show DebugScreen;

/// Public entry point for the DebugLens in-app debugging overlay.
class DebugLens {
  DebugLens._();

  /// Singleton for the instance-side API — the config methods below. Everything
  /// else on this class is static.
  static final DebugLens instance = DebugLens._();

  /// Route name given to DebugLens's own panel route on the host navigator, so
  /// it shows a readable label (instead of `PageRouteBuilder`) on the
  /// Navigation screen.
  static const String panelRouteName = DebugRoutes.panelRouteName;

  /// Master switch for everything DebugLens does. Defaults to **true**.
  ///
  /// With it off, [wrap] returns your app untouched and every capture path is a
  /// no-op: nothing is stored, nothing is persisted, and neither the remote
  /// config nor the app-version override is applied — so your own values are
  /// what your code reads. The interceptor, observers and `record*` calls can
  /// stay exactly where they are.
  ///
  /// **Deciding when to ship it is yours.** The package deliberately doesn't
  /// guess from the build mode, because a QA build is usually a release build
  /// and that is precisely when a tester needs the panel. The common choice:
  ///
  /// ```dart
  /// DebugLens.debugLensEnabled = !kReleaseMode;              // never in production
  /// DebugLens.debugLensEnabled = flavor != Flavor.production; // or per flavor
  /// ```
  ///
  /// Set it in `main`, before [wrap] first builds and before any `record*` call
  /// you want suppressed.
  static set debugLensEnabled(bool value) => DebugLensConfig.enabled = value;

  static bool get debugLensEnabled => DebugLensConfig.enabled;

  /// The role a fresh install starts in. Defaults to [DebugRole.tester], which
  /// can open only the screens a developer has granted it.
  ///
  /// Set it **before** [wrap] first builds — from `main`, alongside your other
  /// startup wiring. It seeds the first launch only: once the role has been
  /// switched on a device the saved choice wins, so flipping this in a later
  /// release won't undo what a tester picked.
  ///
  /// ```dart
  /// DebugLens.initialRole = DebugRole.developer;
  /// ```
  static set initialRole(DebugRole role) => DebugRoleController.initial = role;

  static DebugRole get initialRole => DebugRoleController.initial;

  /// The screens a tester may open on a fresh install. Defaults to just
  /// [DebugScreen.network].
  ///
  /// Set it **before** [wrap] first builds. Like [initialRole] it seeds the
  /// first launch only — once the grants have been edited from Settings on a
  /// device, that set wins.
  ///
  /// ```dart
  /// DebugLens.initialTesterAccess = {
  ///   DebugScreen.network,
  ///   DebugScreen.logs,
  ///   DebugScreen.device,
  /// };
  /// ```
  ///
  /// Settings itself can't be granted: it is where access is configured, so a
  /// tester with it could widen their own.
  static set initialTesterAccess(Set<DebugScreen> screens) =>
      DebugRoleController.initialTesterAccess = {...screens};

  static Set<DebugScreen> get initialTesterAccess =>
      DebugRoleController.initialTesterAccess;

  /// Whether the tester role exists at all on a fresh install. Defaults to
  /// true.
  ///
  /// Set it false for a build that should stay in developer mode — the role
  /// chip then hides itself and there is nothing to step down to. Seeds the
  /// first launch only, as above.
  static set initialTesterEnabled(bool value) =>
      DebugRoleController.initialTesterEnabled = value;

  static bool get initialTesterEnabled =>
      DebugRoleController.initialTesterEnabled;

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

  /// Hands DebugLens the config values you just fetched — Firebase Remote
  /// Config, AWS AppConfig, LaunchDarkly, a hand-rolled flag store.
  ///
  /// DebugLens shows them on the Services screen under [name], infers each
  /// parameter's type from its value, and owns everything about overriding
  /// them: which keys, the source/custom switch, persistence, reset. Label the
  /// non-override side with [sourceLabel].
  ///
  /// **Await it**, once, during startup — it loads the overrides saved on a
  /// previous run, and the getters below only mean anything afterwards.
  ///
  /// Pass raw values (`bool` / `int` / `double` / `String`). If your provider
  /// wraps them — Firebase's `getAll()` returns `RemoteConfigValue` objects —
  /// unwrap first, or the panel shows the wrapper rather than the value.
  Future<void> setRemoteConfigData(
    Map<String, Object?> values, {
    String sourceLabel = DebugStrings.serviceSourceRemote,
    String name = DebugStrings.serviceConfigName,
  }) async {
    await DebugConfigStore.instance.load(values, sourceLabel);
    DebugLensServices.register(DebugConfigService(name: name));
  }

  /// The value in force for [key], or `null` when nothing is registered under
  /// it. The override when one applies this session, otherwise the value you
  /// registered — so this is the whole read, with no fallback to supply.
  ///
  /// Use it directly for anything the typed getters don't cover; they are all
  /// built on it.
  Object? getKey(String key) => DebugConfigStore.instance.resolvedValue(key);

  /// [getKey] as a String — empty when the key is unknown.
  String getString(String key) => getKey(key)?.toString() ?? '';

  /// [getKey] as a bool — `false` when the key is unknown.
  ///
  /// Accepts a real `bool` or the strings `'true'` / `'false'`, since providers
  /// that store everything as text (Firebase Remote Config among them) hand
  /// back the latter.
  bool getBool(String key) {
    final value = getKey(key);
    if (value is bool) return value;
    return value?.toString().toLowerCase() == DebugConstants.trueValue;
  }

  /// [getKey] as an int — `0` when the key is unknown or doesn't parse.
  /// Accepts a real number or its string form.
  int getInt(String key) {
    final value = getKey(key);
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// [getKey] as a double — `0` when the key is unknown or doesn't parse.
  /// Accepts a real number or its string form.
  double getDouble(String key) {
    final value = getKey(key);
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Whether the crash service has been put on the Services screen yet, so
  /// [recordCrash] can register it lazily without clobbering a custom [name]
  /// that [initCrashReporting] already set.
  static bool _crashReportingStarted = false;

  /// Adds the crash-report service to the Services screen under [name]. Call it
  /// from your crash reporter's own `initialize()`, so the screen is there from
  /// startup and an empty list reads as "nothing has gone wrong yet".
  ///
  /// Optional — [recordCrash] registers it on first use if you skip this — but
  /// then the service only appears once something has already failed.
  void initCrashReporting({String name = DebugStrings.serviceCrashName}) {
    _crashReportingStarted = true;
    DebugLensServices.register(DebugCrashService(name: name));
  }

  /// Records a crash or non-fatal on the Services screen's crash service.
  ///
  /// Call it from your `FirebaseCrashlytics.recordError` wrapper (or Sentry's,
  /// or your own) with the same payload you send upstream — DebugLens stamps
  /// the time, keeps the event for this session, and uploads nothing.
  ///
  /// Crash reporters are write-only, which is why this is pushed rather than
  /// pulled like the other services.
  void recordCrash(DebugLensCrashEvent event) {
    if (!_crashReportingStarted) initCrashReporting();
    DebugCrashStore.instance.record(event);
  }

  /// Whether the analytics service has been put on the Services screen yet —
  /// see [_crashReportingStarted].
  static bool _analyticsStarted = false;

  /// Adds the analytics service to the Services screen under [name]. Call it
  /// from your analytics wrapper's own `initialize()`, so the screen is there
  /// from startup rather than appearing with the first event.
  void initAnalytics({String name = DebugStrings.serviceAnalyticsName}) {
    _analyticsStarted = true;
    DebugLensServices.register(DebugAnalyticsService(name: name));
  }

  /// Records an analytics event on the Services screen's analytics service.
  ///
  /// Call it from your `FirebaseAnalytics.logEvent` wrapper (or Amplitude's, or
  /// Segment's) with the same payload you send upstream. [name] is the row
  /// title; [parameters] are the fields shown when the row is expanded — put
  /// everything else in there, DebugLens reads none of it. Nothing is uploaded.
  ///
  /// Analytics SDKs are write-only, which is why this is pushed rather than
  /// pulled like the adapter-based services.
  void recordAnalyticsEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) {
    if (!_analyticsStarted) initAnalytics();
    DebugAnalyticsStore.instance.record(
      DebugLensAnalyticsEvent(name: name, parameters: parameters),
    );
  }

  /// Whether the performance service has been put on the Services screen yet —
  /// see [_crashReportingStarted].
  static bool _performanceStarted = false;

  /// Adds the performance service to the Services screen under [name]. Call it
  /// from your performance wrapper's own `initialize()`, so the screen is there
  /// from startup rather than appearing with the first finished trace.
  void initPerformance({String name = DebugStrings.servicePerformanceName}) {
    _performanceStarted = true;
    DebugLensServices.register(DebugTraceService(name: name));
  }

  /// Records a **finished** trace on the Services screen's performance service.
  ///
  /// Call it where your trace stops — you keep owning the running trace, so
  /// DebugLens never holds a half-timed one. [name] is the row title and
  /// [duration] its second line; fold the trace's metrics and attributes into
  /// [attributes] and they show as fields when the row is expanded. Nothing is
  /// uploaded.
  ///
  /// Performance SDKs are write-only, which is why this is pushed rather than
  /// pulled like the adapter-based services.
  void recordTrace(
    String name,
    Duration duration, {
    Map<String, Object?> attributes = const {},
  }) {
    if (!_performanceStarted) initPerformance();
    DebugTraceStore.instance.record(
      DebugLensTraceEvent(
        name: name,
        duration: duration,
        attributes: attributes,
      ),
    );
  }

  /// Hands DebugLens the app's real version so the panel can show it and, if
  /// a tester overrides it, serve the override back through [appVersion].
  ///
  /// **Await it**, once, during startup — it loads the override saved on a
  /// previous run, and [appVersion] is only meaningful afterwards. Pass
  /// whatever shape you use: `1.0.0`, `1.0.0+42`, `1.0.0-rc.1`.
  Future<void> setAppVersion(String version) =>
      AppVersionStore.instance.load(version);

  /// The version in force this session — the override when one applies,
  /// otherwise what you registered. Read it wherever the app shows or reports
  /// its version, and DebugLens stays out of the path when nothing is
  /// overridden.
  ///
  /// Edits apply on the next app start, so this is stable for the session.
  String get appVersion => AppVersionStore.instance.version;

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
    /// Disabled: hand the app straight back. No bubble, no panel, and none of
    /// the restores below — combined with the guards on every write path,
    /// DebugLens holds nothing and costs nothing.
    if (!DebugLensConfig.enabled) return child;

    /// Restoring the Logs capture switches reads SharedPreferences, which needs
    /// the binding — safe here, since [wrap] runs once the tree is up.
    DebugLensLogger.instance.restoreCaptureSettings();
    DebugLimits.instance.restore();
    DashOrderStore.instance.restore();
    BubbleStore.instance.restore();
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
