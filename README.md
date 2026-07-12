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
