## Inspectors

### Navigation

Records every route transition (push, pop, replace, remove) across your app's
navigators into a live timeline, and keeps a snapshot of the current route
stack. Dialogs and bottom sheets are captured too, classified by kind.

- **Events + Stack tabs** — chronological feed (route name, kind, source
  navigator, time) and the live stack per navigator.
- **Nested navigators** — tab bars / inner navigators via labelled observers.
- **Filter & search** — by route kind, free-text on route name, sort newest/oldest.
- **Route arguments** — inspect and copy as JSON.
- **Share** — export the capture as a log file.

**Usage** — attach the observer to your `MaterialApp`:

```dart
MaterialApp(
  navigatorObservers: [DebugLens.navigatorObserver],
  builder: (context, child) => DebugLens.wrap(child!),
);
```

For a nested navigator (e.g. a bottom-nav tab), give it its own labelled
observer and detach it when disposed:

```dart
final observer = DebugLens.newNavigatorObserver(label: 'home-tab');

Navigator(observers: [observer], /* ... */);

// in dispose():
observer.detach();
```

> Tip: set `RouteSettings(name: ...)` on your routes so they show readable
> names instead of the route's runtime type.

### Network

Captures every HTTP transaction on an instrumented Dio into a live list —
method, URL, status, timing, sizes, headers, and request/response bodies —
plus a session-long per-endpoint call history. Session-only (kept in memory,
ring-buffered to the latest 250; nothing is written to disk).

- **List / detail** — searchable, status-filterable, sortable list; a detail
  view with Overview / Request / Response tabs.
- **History** — every endpoint called this session with its call counts,
  broken down by outcome. Survives clearing the log.
- **Connectivity** — AppBar indicator of the current transport (wifi / mobile
  / offline). Reports transport, not internet reachability.
- **Copy & share** — swipe a row (→ cURL, ← cURL + response); the detail
  screen shares the cURL or an Overview/Request/Response text dump.
- **Safe by default** — `Authorization` / `Cookie` headers are redacted;
  request/response bodies can be turned off.

**Usage** — add the interceptor to each Dio you want to observe:

```dart
final dio = Dio()..interceptors.add(DebugLensDioInterceptor());
```

Tune capture with settings:

```dart
DebugLensDioInterceptor(
  settings: const DebugLensDioInterceptorSettings(
    logToLogger: true,          // mirror into the Logs inspector
    captureRequestBody: true,
    captureResponseBody: true,
    redactSensitiveHeaders: true,
  ),
);
```

### Logs

One feed for everything the app says: your own `.i` / `.d` / `.e` calls plus the
events DebugLens's own observers mirror in. Session-only (in memory, oldest
dropped first). Search and filter by level, tap a row for the message / error /
stack detail.

**Usage** — log from anywhere; nothing to register:

```dart
DebugLensLogger.instance.i('Login succeeded', name: 'auth');
DebugLensLogger.instance.d('Fetched ${posts.length} posts', name: 'api');
DebugLensLogger.instance.e('Charge failed', name: 'payment', error: e, stackTrace: s);
```

`name` is the `[tag]` shown on the row and what search matches on.

Whether records also reach the terminal is yours to set — DebugLens doesn't
assume a build mode. Turn it off when you already have a logger printing, and
the record still shows in the feed with no duplicate line:

```dart
DebugLensLogger.instance.printToConsole = kDebugMode; // or false
```

**Buffer size** — 1000 records by default; lowering it trims immediately:

```dart
DebugLensLogger.instance.maxHistory = 5000;
```

**Crashes** — DebugLens doesn't hook Flutter's error channels for you; point
them at the logger so framework and uncaught async errors land in the feed:

```dart
FlutterError.onError = (details) {
  DebugLensLogger.instance.e(
    details.exceptionAsString(),
    name: 'flutter',
    error: details.exception,
    stackTrace: details.stack,
  );
  FlutterError.presentError(details);
};

PlatformDispatcher.instance.onError = (error, stack) {
  DebugLensLogger.instance.e('Uncaught error', error: error, stackTrace: stack);
  return false;
};
```

> Silence a noisy DebugLens source (Network, Bloc, Navigation) with its
> switch in the capture sheet — the first AppBar action; rows already
> captured stay. Share exports the buffer as a log file.

### Bloc

Records every Bloc/Cubit lifecycle event (create, event, change, transition,
error, close) into a live feed with expandable per-event detail. Session-only
(in memory, ring-buffered to the latest 200).

- **Feed** — chronological rows with an action chip, bloc name and summary;
  expand for current/next state, event payload, and error + stack trace.
- **Filter & search** — by action kind, free-text on bloc name, sort
  newest/oldest.
- **Logs mirror** — each event also lands in the Logs inspector tagged
  `bloc.<RuntimeType>`.
- **Share** — export the feed as a log file.

**Usage** — set the observer once at startup:

```dart
void main() {
  Bloc.observer = DebugLensBlocObserver();
  runApp(const MyApp());
}
```

> Pass `DebugLensBlocObserver(showLogs: false)` to keep the observer installed
> but stop it recording (e.g. in release builds).

### Storage

Inspects the app's persistent state — SharedPreferences and databases — over
two tabs. Pull-based: the host registers read-only sources and DebugLens reads
them on demand, keeping no copy and never importing your storage packages.

- **Prefs** — searchable by key or value, with a colour-coded type chip
  (`bool` / `int` / `double` / `String` / `List`). Encrypted keys are flagged
  `*` and their values hidden by default (eye toggle to reveal). Copy/share
  per row, tap for detail.
- **Databases** — browse each registered database → its tables → rows in a
  `DataTable` with row search and tap-to-sort columns.
- **Refresh** — re-pull on demand and automatically on app resume.

**Usage** — register the sources once (e.g. after storage init). DebugLens
gets a snapshot; your app keeps using its own storage packages directly:

```dart
// SharedPreferences — map your live prefs to DebugLensPrefEntry.
DebugLens.sharedPrefsSource = () => [
  for (final key in prefs.getKeys())
    DebugLensPrefEntry(key: key, value: '${prefs.get(key)}'),
];

// Databases — implement DebugLensDatabase over your DB (drift/sqflite/…).
DebugLens.registerDatabase(myDatabaseAdapter);
```

### Locale

Inspects the app's active localized strings, grouped into collapsible category
dropdowns. Pull-based and read-only: the host registers a source returning the
**current** locale's strings; DebugLens shows that one, keeping no copy.

- **Grouped view** — strings grouped by top-level category (`{category: {key:
  value}}`); flat maps are shown as-is.
- **Search & sort** — free-text on category/key/value, and A→Z / Z→A category
  order.
- **Paginated** — a batch of categories per page, so a large locale stays
  responsive.
- **Refresh & share** — re-pulls on app resume; shares the current (filtered)
  view as a log file.

**Usage** — register the source once (e.g. after the lang data loads); return
the active locale's map + label. Switching language just re-pulls it:

```dart
DebugLens.localeSource = () => DebugLensLocaleData(
  entries: currentLangMap, // nested {category: {key: value}} or flat {key: value}
  label: 'English',
);
```

### Notifications & Deep-links

Records the notifications your app shows/handles and the deep-links it opens,
over two tabs. Push-based: the host reports each event through a one-line call;
DebugLens generates the id and timestamp. Session-only (in memory, newest-first,
ring-buffered to the latest 200 each).

- **Notifications** — title, body, source, and `received` / `tapped` kind, with
  the payload as expandable JSON.
- **Deep-links** — the URI broken into scheme / host / path, with query
  parameters as JSON.
- **Search & sort** — free-text (title/body/source, or URI), toggled between
  recent-first and A–Z. Tab labels show live counts.
- **Copy, share & clear** — copy a row, share the active tab as a log file, or
  clear it from the AppBar.
- **Safe by default** — the payload is deep-copied on record, so later mutations
  of your map never alter the logged entry and non-JSON values are stringified.

**Usage** — report events from your notification / deep-link handlers. Call
`recordNotification` both when a notification is shown and when it's tapped
(`tapped: true`):

```dart
// On show (and again on tap with tapped: true).
DebugLens.recordNotification(
  title: message.title,
  body: message.body,
  payload: message.data,
  source: 'FCM',
);

// From your app-links / deep-link handler.
DebugLens.recordDeeplink(uri.toString(), source: 'os');
```

> Clear programmatically with `DebugLens.clearNotifications()` /
> `DebugLens.clearDeeplinks()`.

### Services

Surfaces whatever backends and SDKs your app talks to — Firebase Analytics,
Crashlytics, Performance, Remote Config, LaunchDarkly, your own API client — as
a list of services, each with its own screen. Vendor-neutral and pull-based: you
implement a small adapter, DebugLens calls it on demand and keeps no copy, so
the package depends on none of these SDKs.

- **Records** — each service renders as expandable rows (an analytics event, a
  trace, a crash report): primary label, optional subtitle, fields as JSON.
- **Remote config** — share your fetched values and DebugLens gives them their
  own screen: flip between the remote values and device-local overrides, and
  edit them in place. See *Remote config* below.
- **Search, sort & share** — free-text over titles and fields, A–Z or original
  order, and a share that exports exactly the rows on screen.
- **Live** — re-pulls on the refresh action, on app resume, and whenever the
  service signals a change, so a screen left open keeps up.
- **Safe by default** — fields listed in `sensitiveKeys` are masked behind an
  eye toggle and always redacted from shared log files.

**Usage** — extend `DebugLensService` (don't implement it: only `name` is
required) and register it once at startup:

```dart
class AnalyticsInspector extends DebugLensService {
  @override
  String get name => 'Analytics';

  @override
  bool get canClear => true;

  @override
  Future<void> clear() async => myAnalytics.clearBuffer();

  /// Optional: re-pull the open screen as new events arrive.
  @override
  Listenable get changes => myAnalytics.revision;

  @override
  Future<List<DebugLensServiceGroup>> load() async => [
    for (final e in myAnalytics.events)
      DebugLensServiceGroup(
        title: e.name,
        subtitle: e.time.toIso8601String(),
        values: {'screen': e.screen, 'token': e.token},
        sensitiveKeys: const {'token'}, // masked + never shared
      ),
  ];
}

DebugLens.registerService(AnalyticsInspector());
```

### Remote config

Override any config value on the device and keep working against it — feature
flags, experiment buckets, copy, timeouts. DebugLens owns all of it: which keys
are overridden, the source/custom switch, persistence, reset. You share what you
fetched, and read back through it.

Keep it to the one file that already wraps your provider:

```dart
class RemoteConfigService {
  RemoteConfigService._();
  static final instance = RemoteConfigService._();

  late final FirebaseRemoteConfig _firebase;

  Future<void> initialize() async {
    _firebase = FirebaseRemoteConfig.instance;
    await _firebase.fetchAndActivate();

    /// Share the fetched values. `getAll()` hands back `RemoteConfigValue`
    /// wrappers — unwrap them, since DebugLens has no Firebase dependency.
    await DebugLens.instance.setRemoteConfigData({
      for (final e in _firebase.getAll().entries) e.key: e.value.asString(),
    }, sourceLabel: 'Firebase');
  }

  Object? getKey(String key) => DebugLens.instance.getKey(key);
  String getString(String key) => DebugLens.instance.getString(key);
  bool getBool(String key) => DebugLens.instance.getBool(key);
  int getInt(String key) => DebugLens.instance.getInt(key);
  double getDouble(String key) => DebugLens.instance.getDouble(key);
}
```

Feature code keeps calling `RemoteConfigService.instance.getInt('key')` and never
learns which side won — so DebugLens stays out of your read paths, and dropping
it leaves you serving the fetched values.

**Await `setRemoteConfigData`.** It loads the overrides saved on a previous run;
without the await, reads race that load and a cold start serves source values.

**Edits apply on the next app start**, which is what the panel's restart dialog
and per-edit toast tell the user. Reads answer from a snapshot taken when you
registered, so flipping the switch and editing a value land at the same moment.

**Types come from the values you share.** Pass real `bool` / `int` / `double` and
each row gets a type chip, a matching keyboard, and edit validation. Firebase
stores everything as text, so `asString()` gives you `String` rows throughout —
map the keys you care about to real types if you want the typed editors.

> `getKey` returns the raw value, or `null` for a key you never registered, for
> anything the four typed getters don't cover — a JSON parameter you want to
> decode yourself, say. The typed getters accept a real value *or* its string
> form, so `getInt` reads `'30'` as `30`.

