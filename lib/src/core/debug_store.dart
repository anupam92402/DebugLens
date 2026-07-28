import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'debug_lens_config.dart';
import '../features/network/domain/api_call_stat.dart';
import '../features/bloc/domain/bloc_event.dart';
import '../features/network/domain/network_entry.dart';
import '../features/notifications/domain/notification_entry.dart';
import '../features/notifications/domain/deeplink_entry.dart';
import '../features/navigation/domain/nav_event.dart';
import '../features/logs/data/debug_lens_logger.dart';
import '../features/services/data/debug_analytics_store.dart';
import '../features/services/data/debug_crash_store.dart';
import '../features/services/data/debug_trace_store.dart';
import '../features/settings/data/debug_limits_store.dart';
import '../features/settings/domain/debug_limit.dart';

/// Holds all captured debug data in memory.
///
/// Everything here is captured live — by the observers, interceptors and
/// loggers that write to [instance]. Data a source can be asked for on demand
/// (services, storage, locale, device info) deliberately isn't held here.
class DebugStore extends ChangeNotifier {
  DebugStore._();

  /// Shared instance: capture sources (observers, interceptors, loggers) write
  /// here, and the UI reads this same instance via Provider `.value`.
  static final DebugStore instance = DebugStore._();

  final List<NetworkEntry> network = <NetworkEntry>[];

  /// Caps come from `DebugLimits`, which is editable from Settings and falls
  /// back to the shipped defaults before it has loaded.
  static int _cap(DebugLimit limit) => DebugLimits.instance.of(limit);

  /// Session-scoped call counts per endpoint (method + path), surfaced on the
  /// Network → History screen. Independent of [network]: [clearNetwork] does
  /// not reset it, so the history reflects the whole session until the app is
  /// killed. Keyed by [_historyKey].
  final Map<String, ApiCallStat> _apiStats = {};

  /// Last status counted for each entry id, so [updateNetwork] can move a call
  /// between buckets (e.g. pending → success) without double-counting [total].
  final Map<String, NetworkStatusKind> _entryStatus = {};

  /// Per-endpoint call stats for the History screen, in first-seen order.
  /// Callers sort/filter as needed.
  List<ApiCallStat> get apiHistory => _apiStats.values.toList(growable: false);

  /// Push/local notifications, newest-first. Populated live via
  /// `DebugLens.recordNotification`; no seed data.
  final List<NotificationEntry> notifications = <NotificationEntry>[];

  /// Captured deep-links, newest-first. Populated live via
  /// `DebugLens.recordDeeplink`; no seed data.
  final List<DeeplinkEntry> deeplinks = <DeeplinkEntry>[];

  final List<NavEvent> navEvents =
      []; // populated live by the navigator observer

  /// Captured BlocObserver lifecycle events (populated by
  /// `DebugLensBlocObserver`). Bottom = oldest, top = newest. Trimmed to
  /// the Bloc limit; the [BlocEvent.sequence] keeps stable IDs
  /// even after trimming.
  final List<BlocEvent> blocEvents = [];
  int _blocSeq = 0;

  /// Live navigator stacks keyed by navigator label (bottom → top), kept by the
  /// observer(s) for the Stack tab. Supports nested navigators.
  final Map<String, List<String>> navStacks = {};

  // Neither SharedPreferences nor database tables are stored here. The Storage
  // screen reads the app's live prefs via `DebugLens.sharedPrefsSource` and its
  // databases via `DebugLens.registerDatabase` — DebugLens keeps no copy. See
  // `debug_shared_prefs_source.dart` and `debug_database_source.dart`.
  // Device/app facts are NOT stored here either. The Device screen reads them
  // live from the platform plugins and the current MediaQuery on each build.
  // See `device_info_source.dart`.

  // Service data is NOT stored here. The Services screen reads each service’s
  // live data on demand via `DebugLens.registerService` and renders it
  // without DebugLens keeping a copy. See `debug_service_source.dart`.

  // Locale data is intentionally NOT stored here. The Locale screen reads the
  // app's live strings on demand via `DebugLens.localeSource` and renders them
  // without DebugLens keeping a copy. See `debug_locale_source.dart`.

  int _navSeq = 0;

  /// Records a navigation transition (used by `DebugLensNavigatorObserver` and
  /// any manual logging). Events are appended in arrival order; [NavEvent.sequence]
  /// stays stable even after the ring buffer trims the oldest entries.
  void recordNavigation({
    required NavAction action,
    required String routeName,
    String? previousRoute,
    Object? arguments,
    String navigator = 'root',
    NavRouteKind kind = NavRouteKind.page,
  }) {
    _navSeq++;
    if (!DebugLensConfig.enabled) return;
    navEvents.add(
      NavEvent(
        sequence: _navSeq,
        action: action,
        kind: kind,
        routeName: routeName,
        previousRoute: previousRoute,
        arguments: _snapshotArguments(arguments),
        time: DateTime.now(),
        navigator: navigator,
      ),
    );
    if (navEvents.length > _cap(DebugLimit.navigation)) navEvents.removeAt(0);
    notifyListeners();
  }

  /// Replaces the live stack snapshot for [navigator] (bottom → top). An empty
  /// list removes that navigator. Not cleared by [clearAll] — it reflects the
  /// app's current routes, not history.
  void setNavStack(String navigator, List<String> routes) {
    if (!DebugLensConfig.enabled) return;
    if (routes.isEmpty) {
      navStacks.remove(navigator);
    } else {
      navStacks[navigator] = List.of(routes);
    }
    notifyListeners();
  }

  /// Drops a navigator's stack snapshot — call when a nested navigator is
  /// disposed (see `DebugLensNavigatorObserver.detach`).
  void removeNavStack(String navigator) {
    if (!DebugLensConfig.enabled) return;
    if (navStacks.remove(navigator) != null) notifyListeners();
  }

  /// Returns a deep copy of [args] decoupled from the app's live object graph,
  /// so later mutations don't change the logged value and no large object is
  /// pinned in memory by the log. Non-JSON values fall back to their
  /// `toString()` representation.
  static Object? _snapshotArguments(Object? args) {
    if (args == null) return null;
    try {
      return jsonDecode(jsonEncode(args, toEncodable: (o) => o.toString()));
    } catch (_) {
      return args.toString();
    }
  }

  /// Appends a new network entry. Used by `DebugLensDioInterceptor` to
  /// register a request as pending the moment it goes out.
  void recordNetwork(NetworkEntry entry) {
    if (!DebugLensConfig.enabled) return;
    network.add(entry);
    if (network.length > _cap(DebugLimit.network)) network.removeAt(0);
    _recordHistory(entry);
    notifyListeners();
  }

  /// Replaces the entry with id [entry.id] (typically a pending request being
  /// completed with a response or an error). No-op if no matching id exists.
  void updateNetwork(NetworkEntry entry) {
    if (!DebugLensConfig.enabled) return;
    final idx = network.indexWhere((e) => e.id == entry.id);
    if (idx == -1) {
      network.add(entry);
    } else {
      network[idx] = entry;
    }
    _updateHistory(entry);
    notifyListeners();
  }

  /// Marks a still-pending entry (by [id]) as errored — used by the
  /// interceptor to close out abandoned requests that never completed.
  void markNetworkError(String id, String message) {
    if (!DebugLensConfig.enabled) return;
    final idx = network.indexWhere((e) => e.id == id);
    if (idx == -1 || !network[idx].isPending) return;
    network[idx] = network[idx].copyWith(error: message);
    _updateHistory(network[idx]);
    notifyListeners();
  }

  /// Clears the captured network entries. Intentionally does **not** touch the
  /// session call history ([apiHistory]) — that survives until app restart.
  void clearNetwork() {
    network.clear();
    notifyListeners();
  }

  // --- Session call history (History screen) -------------------------------

  /// History bucket key: method + endpoint path (query string dropped so the
  /// same endpoint hit with different params aggregates together).
  static String _historyKey(NetworkEntry e) => '${e.methodLabel} ${e.path}';

  void _bumpStatus(ApiCallStat s, NetworkStatusKind kind, int delta) {
    switch (kind) {
      case NetworkStatusKind.success:
        s.success += delta;
      case NetworkStatusKind.error:
        s.error += delta;
      case NetworkStatusKind.pending:
        s.pending += delta;
    }
  }

  /// Counts a freshly recorded call against its endpoint.
  void _recordHistory(NetworkEntry entry) {
    final stat = _apiStats.putIfAbsent(
      _historyKey(entry),
      () => ApiCallStat(
        method: entry.method,
        path: entry.path,
        lastCalled: entry.requestTime,
      ),
    );
    final status = entry.statusKind;
    stat.recordCall(entry.requestTime);
    _bumpStatus(stat, status, 1);
    _entryStatus[entry.id] = status;
  }

  /// Re-buckets a call whose status changed (e.g. pending → success). Falls
  /// back to recording it fresh if it was never seen (e.g. an update with no
  /// prior pending record).
  void _updateHistory(NetworkEntry entry) {
    final stat = _apiStats[_historyKey(entry)];
    final prev = _entryStatus[entry.id];
    if (stat == null || prev == null) {
      _recordHistory(entry);
      return;
    }
    final next = entry.statusKind;
    if (prev != next) {
      _bumpStatus(stat, prev, -1);
      _bumpStatus(stat, next, 1);
    }
    stat.lastCalled = entry.requestTime;
    _entryStatus[entry.id] = next;
  }

  /// Clears only the navigation event log (Events tab). The live stack snapshot
  /// is left intact since it reflects the app's current routes.
  void clearNavigation() {
    navEvents.clear();
    _navSeq = 0;
    notifyListeners();
  }

  /// Appends a Bloc lifecycle event (called from `DebugLensBlocObserver`).
  /// The ring buffer trims the oldest entries past [_maxBlocEvents].
  void recordBlocEvent({
    required BlocActionKind kind,
    required String blocName,
    String? event,
    String? currentState,
    String? nextState,
    String? error,
    String? stackTrace,
  }) {
    _blocSeq++;
    if (!DebugLensConfig.enabled) return;
    blocEvents.add(
      BlocEvent(
        sequence: _blocSeq,
        kind: kind,
        blocName: blocName,
        time: DateTime.now(),
        event: event,
        currentState: currentState,
        nextState: nextState,
        error: error,
        stackTrace: stackTrace,
      ),
    );
    if (blocEvents.length > _cap(DebugLimit.bloc)) blocEvents.removeAt(0);
    notifyListeners();
  }

  /// Clears only the Bloc events list.
  void clearBlocEvents() {
    blocEvents.clear();
    _blocSeq = 0;
    notifyListeners();
  }

  /// Deep-copies a notification [payload] so the logged entry is decoupled from
  /// the caller's live map (later mutations don't alter it) and non-JSON values
  /// fall back to `toString()`. Reuses [_snapshotArguments]; on any failure the
  /// keys are kept with stringified values.
  static Map<String, Object?> snapshotPayload(Map<String, Object?> payload) {
    if (payload.isEmpty) return const {};
    final snap = _snapshotArguments(payload);
    if (snap is Map<String, Object?>) return snap;
    return {for (final e in payload.entries) e.key: e.value?.toString()};
  }

  /// Records a push/local notification (called from `DebugLens.recordNotification`).
  /// Inserted newest-first; the ring buffer trims the oldest past
  /// the notifications limit.
  void recordNotification(NotificationEntry entry) {
    if (!DebugLensConfig.enabled) return;
    notifications.insert(0, entry);
    if (notifications.length > _cap(DebugLimit.notifications)) {
      notifications.removeLast();
    }
    notifyListeners();
  }

  /// Records a captured deep-link (called from `DebugLens.recordDeeplink`).
  /// Inserted newest-first; the ring buffer trims the oldest past
  /// the deep-links limit.
  void recordDeeplink(DeeplinkEntry entry) {
    if (!DebugLensConfig.enabled) return;
    deeplinks.insert(0, entry);
    if (deeplinks.length > _cap(DebugLimit.deeplinks)) deeplinks.removeLast();
    notifyListeners();
  }

  /// Clears the captured notifications (Notifications tab).
  void clearNotifications() {
    notifications.clear();
    notifyListeners();
  }

  /// Clears the captured deep-links (Deep-links tab).
  void clearDeeplinks() {
    deeplinks.clear();
    notifyListeners();
  }

  /// Wipes every captured feed — not just the ones this store owns.
  ///
  /// The logger and the three pushed service stores keep their own buffers, so
  /// "clear all data" has to reach into them too; leaving them out made the
  /// Settings action quietly partial. The live navigator stacks are the one
  /// exception: they describe where the app is right now, not what it did.
  void clearAll() {
    network.clear();
    _apiStats.clear();
    _entryStatus.clear();
    blocEvents.clear();
    _blocSeq = 0;
    notifications.clear();
    deeplinks.clear();
    navEvents.clear();
    _navSeq = 0;
    notifyListeners();

    // Each notifies its own listeners.
    DebugLensLogger.instance.clear();
    DebugCrashStore.instance.clear();
    DebugAnalyticsStore.instance.clear();
    DebugTraceStore.instance.clear();
  }
}
