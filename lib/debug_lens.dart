/// An in-app debugging overlay for Flutter: a draggable bubble opens a panel
/// that surfaces network calls, logs, bloc/navigation events, storage and
/// device facts, plus whatever you push in from your own crash reporter,
/// analytics or remote config.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/features/storage/data/debug_database_source.dart';
import 'src/shared/debug_constants.dart';
import 'src/shared/debug_strings.dart';
import 'src/features/services/data/debug_analytics_store.dart';
import 'src/features/settings/data/app_version_store.dart';
import 'src/features/settings/data/bubble_store.dart';
import 'src/features/settings/data/debug_limits_store.dart';
import 'src/features/settings/domain/debug_lens_limits.dart';
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
import 'src/features/logs/domain/log_origin.dart';
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
export 'src/features/settings/domain/debug_lens_limits.dart'
    show DebugLensLimits;
export 'src/core/debug_role.dart' show DebugRole;
export 'src/core/debug_screen.dart' show DebugScreen;

/// Public entry point for the DebugLens in-app debugging overlay.
class DebugLens {
  DebugLens._();

  /// Instance-side API; everything else on this class is static.
  static final DebugLens instance = DebugLens._();

  /// Route name of the panel route on the host navigator.
  static const String panelRouteName = DebugRoutes.panelRouteName;

  /// Master switch. Defaults to true; off makes [wrap] and every capture path
  /// a no-op. Set it in `main`, before [wrap] first builds.
  ///
  /// ```dart
  /// DebugLens.debugLensEnabled = !kReleaseMode;
  /// ```
  static set debugLensEnabled(bool value) => DebugLensConfig.enabled = value;

  static bool get debugLensEnabled => DebugLensConfig.enabled;

  /// The role a fresh install starts in. Defaults to [DebugRole.tester].
  ///
  /// Seeds the first launch only — a role switched on a device wins after that.
  /// Set before [wrap] first builds.
  static set initialRole(DebugRole role) => DebugRoleController.initial = role;

  static DebugRole get initialRole => DebugRoleController.initial;

  /// Screens a tester may open on a fresh install. Defaults to
  /// [DebugScreen.network]; Settings is never grantable.
  ///
  /// Seeds the first launch only. Set before [wrap] first builds.
  static set initialTesterAccess(Set<DebugScreen> screens) =>
      DebugRoleController.initialTesterAccess = {...screens};

  static Set<DebugScreen> get initialTesterAccess =>
      DebugRoleController.initialTesterAccess;

  /// Whether the tester role exists at all. Defaults to true; false hides the
  /// role chip. Seeds the first launch only.
  static set initialTesterEnabled(bool value) =>
      DebugRoleController.initialTesterEnabled = value;

  static bool get initialTesterEnabled =>
      DebugRoleController.initialTesterEnabled;

  /// How many records each feed keeps. Feeds left null keep the shipped limit.
  ///
  /// ```dart
  /// DebugLens.initialLimits = const DebugLensLimits(network: 1000, logs: 5000);
  /// ```
  ///
  /// Seeds the first launch only, per feed. Set before [wrap] first builds.
  static set initialLimits(DebugLensLimits limits) =>
      DebugLimits.initial = limits;

  static DebugLensLimits get initialLimits => DebugLimits.initial;

  /// Add to your `MaterialApp.navigatorObservers` to capture navigation events.
  static final NavigatorObserver navigatorObserver =
      DebugLensNavigatorObserver();

  /// Observer for a nested [Navigator]. [label] groups its events and gives it
  /// its own Stack entry; call `detach()` when that navigator is disposed.
  static DebugLensNavigatorObserver newNavigatorObserver({
    required String label,
  }) => DebugLensNavigatorObserver(label: label);

  /// Pull-based source for the Locale screen, called on each build. Keeps no
  /// copy; pass `null` to clear.
  static set localeSource(DebugLensLocaleSource? source) =>
      DebugLensLocale.source = source;

  static DebugLensLocaleSource? get localeSource => DebugLensLocale.source;

  /// Pull-based source for the Storage screen's SharedPrefs tab, called on each
  /// build. Keeps no copy; pass `null` to clear.
  static set sharedPrefsSource(DebugLensSharedPrefsSource? source) {
    DebugLensSharedPrefs.source = source;
    _mirrorToLogs(
      DebugLogOrigin.storage,
      source == null ? 'prefs source cleared' : 'prefs source registered',
      'storage.prefs',
    );
  }

  static DebugLensSharedPrefsSource? get sharedPrefsSource =>
      DebugLensSharedPrefs.source;

  /// Registers a database for the Storage screen's Database tab. Read on
  /// demand; idempotent by [DebugLensDatabase.name].
  static void registerDatabase(DebugLensDatabase database) {
    DebugLensDatabases.register(database);
    _mirrorToLogs(
      DebugLogOrigin.storage,
      'database registered: ${database.name}',
      'storage.database',
    );
  }

  /// The registered databases shown in the Database tab.
  static List<DebugLensDatabase> get databases => DebugLensDatabases.sources;

  /// Registers a service for the Services screen. Its `load()` is called on
  /// demand; idempotent by [DebugLensService.name].
  static void registerService(DebugLensService service) {
    DebugLensServices.register(service);
    _mirrorToLogs(
      DebugLogOrigin.services,
      'service registered: ${service.name}',
      'service',
    );
  }

  /// The registered services shown on the Services screen.
  static List<DebugLensService> get services => DebugLensServices.services;

  /// Registers fetched config values on the Services screen under [name],
  /// where a tester can override any of them. [sourceLabel] names the
  /// non-override side.
  ///
  /// Await once during startup: it loads the overrides saved on a previous run,
  /// which the getters below serve. Pass raw values, not provider wrappers.
  Future<void> setRemoteConfigData(
    Map<String, Object?> values, {
    String sourceLabel = DebugStrings.serviceSourceRemote,
    String name = DebugStrings.serviceConfigName,
  }) async {
    await DebugConfigStore.instance.load(values, sourceLabel);
    DebugLensServices.register(DebugConfigService(name: name));
    _mirrorToLogs(
      DebugLogOrigin.services,
      '$sourceLabel: ${values.length} parameters',
      'config',
    );
  }

  /// The value in force for [key] — the override when one applies, otherwise
  /// the registered value. Null when the key is unknown.
  Object? getKey(String key) => DebugConfigStore.instance.resolvedValue(key);

  /// [getKey] as a String — empty when the key is unknown.
  String getString(String key) => getKey(key)?.toString() ?? '';

  /// [getKey] as a bool — `false` when unknown. Accepts a `bool` or the
  /// strings `'true'` / `'false'`.
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

  /// Whether the crash service is on the Services screen yet.
  static bool _crashReportingStarted = false;

  /// Adds the crash service to the Services screen under [name], so it is there
  /// from startup. Optional: [recordCrash] registers it on first use.
  void initCrashReporting({String name = DebugStrings.serviceCrashName}) {
    _crashReportingStarted = true;
    DebugLensServices.register(DebugCrashService(name: name));
  }

  /// Records a crash or non-fatal. Call from your crash reporter's wrapper with
  /// the payload you send upstream; the event stays on the device.
  void recordCrash(DebugLensCrashEvent event) {
    if (!_crashReportingStarted) initCrashReporting();
    DebugCrashStore.instance.record(event);
    final logger = DebugLensLogger();
    if (logger.isCapturing(DebugLogOrigin.services)) {
      logger.e(
        '${event.fatal ? 'fatal' : 'non-fatal'}: ${event.error}',
        name: 'crash',
        error: event.error,
        stackTrace: event.stackTrace,
      );
    }
  }

  /// Whether the analytics service is on the Services screen yet.
  static bool _analyticsStarted = false;

  /// Adds the analytics service to the Services screen under [name], so it is
  /// there from startup.
  void initAnalytics({String name = DebugStrings.serviceAnalyticsName}) {
    _analyticsStarted = true;
    DebugLensServices.register(DebugAnalyticsService(name: name));
  }

  /// Records an analytics event. [name] is the row title and [parameters] the
  /// fields shown when it expands; nothing is uploaded.
  void recordAnalyticsEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) {
    if (!_analyticsStarted) initAnalytics();
    DebugAnalyticsStore.instance.record(
      DebugLensAnalyticsEvent(name: name, parameters: parameters),
    );
    _mirrorToLogs(
      DebugLogOrigin.services,
      parameters.isEmpty ? name : '$name $parameters',
      'analytics',
    );
  }

  /// Whether the performance service is on the Services screen yet.
  static bool _performanceStarted = false;

  /// Adds the performance service to the Services screen under [name], so it is
  /// there from startup.
  void initPerformance({String name = DebugStrings.servicePerformanceName}) {
    _performanceStarted = true;
    DebugLensServices.register(DebugTraceService(name: name));
  }

  /// Records a finished trace. Call it where your trace stops: [duration] is
  /// the row's second line and [attributes] its expanded fields.
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
    _mirrorToLogs(
      DebugLogOrigin.services,
      '$name ${duration.inMilliseconds}ms',
      'trace',
    );
  }

  /// Registers the app's real version, in whatever shape you use. Await once
  /// during startup: it loads the override saved on a previous run.
  Future<void> setAppVersion(String version) =>
      AppVersionStore.instance.load(version);

  /// The version in force this session — the override when one applies,
  /// otherwise what was registered. Edits apply on the next app start.
  String get appVersion => AppVersionStore.instance.version;

  /// Records a push or local notification. Call on display and on tap
  /// ([tapped] true); [source] labels the origin, e.g. `FCM` or `local`.
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
    _mirrorToLogs(
      DebugLogOrigin.notifications,
      '${tapped ? 'tapped' : 'received'}: ${title ?? body ?? DebugConstants.emptyValue}',
      'notification.$source',
    );
  }

  /// Clears the captured notifications shown on the Notifications tab.
  static void clearNotifications() => DebugStore.instance.clearNotifications();

  /// Clears the captured deep-links shown on the Deep-links tab.
  static void clearDeeplinks() => DebugStore.instance.clearDeeplinks();

  /// Records a captured deep link. [source] labels the origin, e.g. `push`,
  /// `browser` or `in-app`.
  static void recordDeeplink(String uri, {String? source}) {
    DebugStore.instance.recordDeeplink(
      DeeplinkEntry(
        id: _nextRecordId('dl'),
        uri: uri,
        time: DateTime.now(),
        source: source,
      ),
    );
    _mirrorToLogs(
      DebugLogOrigin.notifications,
      uri,
      source == null ? 'deeplink' : 'deeplink.$source',
    );
  }

  /// Mirrors a pushed record into the Logs feed, unless [origin]'s capture
  /// switch is off.
  static void _mirrorToLogs(DebugLogOrigin origin, String message, String tag) {
    final logger = DebugLensLogger();
    if (!logger.isCapturing(origin)) return;
    logger.d(message, name: tag);
  }

  /// Monotonic suffix so records in the same millisecond stay unique.
  static int _recordSeq = 0;

  static String _nextRecordId(String prefix) {
    _recordSeq++;
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$_recordSeq';
  }

  /// Wraps [child] (use from `MaterialApp.builder`) to provide the DebugLens
  /// state and overlay a draggable bubble. Tapping the bubble opens the panel.
  static Widget wrap(Widget child) {
    // Disabled: hand the app back untouched.
    if (!DebugLensConfig.enabled) return child;

    // These read SharedPreferences, so they need the binding [wrap] runs under.
    DebugLensLogger().restoreCaptureSettings();
    DebugLimits.instance.restore();
    BubbleStore.instance.restore();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DebugLensController()),
        ChangeNotifierProvider(create: (_) => DebugRoleController()),
        ChangeNotifierProvider<DebugStore>.value(value: DebugStore.instance),
        ChangeNotifierProvider<DebugLensLogger>.value(value: DebugLensLogger()),
      ],
      child: _DebugLensHost(child: child),
    );
  }

  /// Opens the panel as a route on the host navigator, so system back closes
  /// it. No-op when already open or the navigator isn't ready. [context] must
  /// be below [wrap].
  static void show(BuildContext context) {
    final controller = context.read<DebugLensController>();
    if (controller.isOpen) return;
    final navigator = navigatorObserver.navigator;
    if (navigator == null) return;
    final route = PageRouteBuilder<void>(
      settings: const RouteSettings(name: panelRouteName),
      // Non-opaque so the app stays visible behind the panel's glass.
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
