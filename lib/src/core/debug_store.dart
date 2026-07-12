import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../features/network/domain/api_call_stat.dart';
import '../features/bloc/domain/bloc_event.dart';
import '../features/network/domain/network_entry.dart';
import '../features/notifications/domain/notification_entry.dart';
import '../features/notifications/domain/deeplink_entry.dart';
import '../features/navigation/domain/nav_event.dart';
import '../features/device/domain/device_app_info.dart';
import 'mock/mock_seed.dart';

/// Holds all captured debug data in memory.
///
/// For the UI scaffold the lists are seeded from [MockSeed]; real capture
/// sources will replace the seeds feature-by-feature.
class DebugStore extends ChangeNotifier {
  DebugStore._();

  /// Shared instance: capture sources (observers, interceptors, loggers) write
  /// here, and the UI reads this same instance via Provider `.value`.
  static final DebugStore instance = DebugStore._();

  final List<NetworkEntry> network = <NetworkEntry>[];

  /// Cap on retained network entries — ring-buffered like nav/bloc so a long
  /// session doesn't grow unbounded (each entry can hold full bodies).
  static const int _maxNetworkEntries = 250;

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

  final List<NotificationEntry> notifications = List.of(
    MockSeed.notifications(),
  );
  final List<DeeplinkEntry> deeplinks = List.of(MockSeed.deeplinks());
  final List<NavEvent> navEvents =
      []; // populated live by the navigator observer

  /// Captured BlocObserver lifecycle events (populated by
  /// `DebugLensBlocObserver`). Bottom = oldest, top = newest. Trimmed to
  /// [_maxBlocEvents] entries; the [BlocEvent.sequence] keeps stable IDs
  /// even after trimming.
  final List<BlocEvent> blocEvents = [];
  int _blocSeq = 0;
  static const int _maxBlocEvents = 200;

  /// Live navigator stacks keyed by navigator label (bottom → top), kept by the
  /// observer(s) for the Stack tab. Supports nested navigators.
  final Map<String, List<String>> navStacks = {};

  // Neither SharedPreferences nor database tables are stored here. The Storage
  // screen reads the app's live prefs via `DebugLens.sharedPrefsSource` and its
  // databases via `DebugLens.registerDatabase` — DebugLens keeps no copy. See
  // `debug_shared_prefs_source.dart` and `debug_database_source.dart`.
  final List<InfoSection> deviceInfo = List.of(MockSeed.deviceInfo());

  // Firebase data is NOT stored here. The Firebase screen reads each service's
  // live data on demand via `DebugLens.registerFirebaseService` and renders it
  // without DebugLens keeping a copy. See `debug_firebase_source.dart`.

  // Locale data is intentionally NOT stored here. The Locale screen reads the
  // app's live strings on demand via `DebugLens.localeSource` and renders them
  // without DebugLens keeping a copy. See `debug_locale_source.dart`.

  int _navSeq = 0;
  static const int _maxNavEvents = 500;

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
    if (navEvents.length > _maxNavEvents) navEvents.removeAt(0);
    notifyListeners();
  }

  /// Replaces the live stack snapshot for [navigator] (bottom → top). An empty
  /// list removes that navigator. Not cleared by [clearAll] — it reflects the
  /// app's current routes, not history.
  void setNavStack(String navigator, List<String> routes) {
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
    network.add(entry);
    if (network.length > _maxNetworkEntries) network.removeAt(0);
    _recordHistory(entry);
    notifyListeners();
  }

  /// Replaces the entry with id [entry.id] (typically a pending request being
  /// completed with a response or an error). No-op if no matching id exists.
  void updateNetwork(NetworkEntry entry) {
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
    stat.total += 1;
    stat.lastCalled = entry.requestTime;
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
    if (blocEvents.length > _maxBlocEvents) blocEvents.removeAt(0);
    notifyListeners();
  }

  /// Clears only the Bloc events list.
  void clearBlocEvents() {
    blocEvents.clear();
    _blocSeq = 0;
    notifyListeners();
  }

  void clearAll() {
    network.clear();
    blocEvents.clear();
    _blocSeq = 0;
    notifications.clear();
    deeplinks.clear();
    navEvents.clear();
    _navSeq = 0;
    notifyListeners();
  }
}
