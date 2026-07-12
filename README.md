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
