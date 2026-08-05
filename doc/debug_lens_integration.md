# Integrate DebugLens with your AI assistant

Copy everything below the line into your AI coding assistant — Claude, Cursor,
Copilot, Antigravity, Windsurf, or any tool that can read and edit your
project — and answer the questions it asks.

---

You are integrating the `debug_lens` Flutter package into this project.
DebugLens is an on-device debug panel: a draggable bubble opens inspectors for
network calls, logs, bloc events, navigation, storage, locale, notifications,
deep links, remote config, crashes, analytics and performance traces. Nothing
it captures leaves the device.

Follow the steps below in order. Do not skip Step 1.

## Step 1 — Ask which services to integrate (FIRST, one single message)

Before touching any code, ask the user this, as one message, and wait for the
answer:

> DebugLens core (the bubble, the panel, and the Navigation inspector) is
> always installed. Which of these inspectors should I also wire up? Reply
> with numbers, e.g. `1 3 4`, or `all`.
>
> 1. **Network** — capture every Dio request/response (requires the app to use Dio)
> 2. **Logs** — an on-device log feed; also routes Flutter's own errors into it
> 3. **Bloc** — every bloc/cubit event and state transition (requires flutter_bloc/bloc)
> 4. **Storage: SharedPreferences** — view live prefs on the device
> 5. **Storage: Database** — browse local database tables (Drift, sqflite, …)
> 6. **Locale** — view the app's active translation strings
> 7. **Notifications & deep links** — every notification shown/tapped and every deep link handled
> 8. **Remote config** — view fetched values and override them on-device
> 9. **Crash reports** — keep every reported crash on the device, stack trace included
> 10. **Analytics** — see every analytics event as it is logged
> 11. **Performance** — record durations of operations you time
> 12. **App version** — override the version string the app reports, without rebuilding
> 13. **Custom error screen** — replace Flutter's red error box with a readable, shareable one

Do not ask follow-up configuration questions beyond this list (no questions
about nested navigators, tester roles, retention limits, header redaction —
those are advanced options the user can add later). Use the sensible defaults
described below.

## Step 2 — Explore the project before editing

Locate and read, in this project:
- `pubspec.yaml` — confirm/record the app's dependencies (Dio? bloc? shared_preferences? Drift/sqflite? Firebase?).
- The file containing `void main()` and the file containing the root `MaterialApp` (or `MaterialApp.router`).
- If the user selected a service, find the class that owns that concern (the Dio client factory, the analytics wrapper, the notification service, etc.). DebugLens calls belong **inside the owning class**, not scattered through feature code.

If a selected service has no matching dependency (e.g. Network selected but no
Dio, Bloc selected but no bloc package), tell the user and skip that service —
do not add the missing dependency yourself.

## Step 2b — Compatibility check (before adding anything)

DebugLens 0.0.2 requires **Dart SDK `^3.9.0`** and **Flutter `>=3.35.0`**.
Check the toolchain (`flutter --version`, and the project's `environment:` in
`pubspec.yaml`). If it's below either minimum, stop here and tell the user to
upgrade Flutter first — do not attempt workarounds.

DebugLens also depends on packages the app may already use. Its constraints
in 0.0.2:

| Package | DebugLens needs | Likely conflict |
| --- | --- | --- |
| `bloc` | `^9.2.1` | apps on `flutter_bloc ^8.x` — fix is upgrading to `flutter_bloc ^9.x` |
| `dio` | `^5.4.0` | apps still on dio 4.x |
| `provider` | `^6.1.2` | rarely conflicts |
| `shared_preferences` | `^2.3.2` | rarely conflicts |
| `connectivity_plus` | `^7.3.1` | apps pinning an older major |
| `device_info_plus` | `^13.2.0` | apps pinning an older major |
| `package_info_plus` | `^10.2.1` | apps pinning an older major |
| `share_plus` | `^13.3.0` | apps pinning an older major |
| `path_provider` | `^2.1.5` | rarely conflicts |

Compare against the project's `pubspec.yaml` and warn the user **up front**
about any collision you can already see. This table is a heads-up, not the
authority — `flutter pub get`'s solver output is. If it fails after adding
`debug_lens`, report exactly which package collided and what upgrade would
resolve it, and get the user's explicit yes before changing any of their
existing dependency versions. Never resolve a conflict with
`dependency_overrides` or by downgrading `debug_lens` unless the user
explicitly asks for that.

## Step 3 — Core setup (always, regardless of answers)

1. Add the dependency to `pubspec.yaml` under `dependencies:`
   ```yaml
   debug_lens: ^0.0.2
   ```
   and run `flutter pub get` (or ask the user to). If version solving fails,
   follow the conflict procedure in Step 2b.

2. In `main()`, **before `runApp`**, set the master switch:
   ```dart
   DebugLens.debugLensEnabled = !kReleaseMode; // adjust to the project's flavor flag if one exists
   ```
   If the project has a flavor/environment flag (staging vs production), gate
   on that instead of `kReleaseMode` — a QA build is usually a release build,
   and that is exactly when the panel is wanted. Off, every DebugLens call in
   the app becomes a no-op, so nothing else needs guarding.

3. On the root `MaterialApp`:
   ```dart
   MaterialApp(
     navigatorObservers: [DebugLens.navigatorObserver], // feeds Navigation; also lets the bubble open the panel
     builder: (context, child) => DebugLens.wrap(child ?? const SizedBox.shrink()),
   );
   ```
   If a `builder` already exists, wrap its result: `DebugLens.wrap(existingResult)`.
   If `navigatorObservers` already exists, append to the list. Both are
   required — without the observer the bubble cannot open the panel.

Everything below is opt-in per the user's Step 1 answer.

## Step 4 — Per-service integration

**Critical API fact:** config/crash/analytics/performance/version push APIs are
**instance** members (`DebugLens.instance.…`); everything else (`wrap`,
`navigatorObserver`, `recordNotification`, `recordDeeplink`, pull sources,
registries, `DebugLensLogger()`) is **static** or a top-level class. Only two
calls must be awaited: `setRemoteConfigData` and `setAppVersion`.

### 1. Network
In the class where the app constructs its `Dio` instance(s), add as the
**last** interceptor:
```dart
dio.interceptors.add(DebugLensDioInterceptor());
```
Cover every Dio the app builds (if there is a client factory, add it there once).

### 2. Logs
In `main()`, before `runApp`:
```dart
DebugLensLogger().printToConsole = kDebugMode; // avoid double console output if another logger prints

FlutterError.onError = (details) {
  DebugLensLogger().e(details.exceptionAsString(),
      name: 'flutter', error: details.exception, stackTrace: details.stack);
  FlutterError.presentError(details);
};
PlatformDispatcher.instance.onError = (error, stack) {
  DebugLensLogger().e('Uncaught error', name: 'app', error: error, stackTrace: stack);
  return false;
};
```
If the project already sets `FlutterError.onError`, add the DebugLens line
into the existing handler instead of replacing it. If the project has its own
logger class, mirror into DebugLens from inside it:
`DebugLensLogger().i/d/e(message, name: tag)` — and set `printToConsole = false`
if that logger already prints.

### 3. Bloc
In `main()`, before `runApp`:
```dart
Bloc.observer = DebugLensBlocObserver();
```
If a custom `BlocObserver` already exists, either have it extend
`DebugLensBlocObserver` or forward every callback to an instance of it.

### 4. Storage: SharedPreferences
Where the app initializes SharedPreferences, register a pull source (called on
demand every time the screen builds — keep it cheap, return live data):
```dart
DebugLens.sharedPrefsSource = () => [
  for (final key in prefs.getKeys())
    DebugLensPrefEntry(key: key, value: '${prefs.get(key)}'),
];
```
`DebugLensPrefEntry` also accepts `type: DebugLensPrefType.…` and
`encrypted: true` for keys whose values shouldn't display in plain text.

### 5. Storage: Database
Implement the read-only adapter for the project's database and register it
where the database is created:
```dart
class MyDbAdapter implements DebugLensDatabase {
  MyDbAdapter(this._db);
  final MyDatabase _db;

  @override
  String get name => 'app.db';

  @override
  Future<List<String>> tableNames() async => /* list of table names */;

  @override
  Future<DebugLensTableData> tableData(String table) async {
    final rows = await /* SELECT * FROM "$table" as List<Map<String, Object?>> */;
    if (rows.isEmpty) return DebugLensTableData.empty;
    return DebugLensTableData(
      columns: rows.first.keys.toList(),
      rows: [for (final r in rows) [for (final c in r.keys) '${r[c]}']],
    );
  }
}

DebugLens.registerDatabase(MyDbAdapter(db));
```
For Drift use `db.allTables` and `customSelect`; for sqflite query
`sqlite_master` for names and `rawQuery` per table.

### 6. Locale
Wherever the app holds its active string map / translations, register a pull
source that reads the **live** state:
```dart
DebugLens.localeSource = () => DebugLensLocaleData(
  entries: currentTranslationsMap, // flat {key: value} or nested {category: {key: value}}
  label: 'English',                // human-readable current locale
);
```
Re-assign it whenever the language switches so the label stays correct.

### 7. Notifications & deep links
Inside the class that shows/handles notifications, record on **display** and
again on **tap**:
```dart
DebugLens.recordNotification(
  title: message.title, body: message.body,
  payload: message.data, source: 'FCM',        // or 'local', 'CleverTap', …
);
// on tap:
DebugLens.recordNotification(..., tapped: true);
```
Where deep links are handled:
```dart
DebugLens.recordDeeplink(uri.toString(), source: 'push'); // or 'os', 'in-app'
```
Redact any secret query parameters before recording.

### 8. Remote config
In the app's remote-config wrapper, right after fetch/activate — **awaited,
once per startup** (it also loads overrides saved on a previous run):
```dart
await DebugLens.instance.setRemoteConfigData({
  for (final e in remoteConfig.getAll().entries) e.key: e.value.asString(),
}, sourceLabel: 'Firebase');
```
Then route the app's config **reads** through DebugLens so on-device overrides
take effect, falling back to the provider:
```dart
bool getBool(String key) =>
    (DebugLens.instance.getKey(key) as bool?) ?? remoteConfig.getBool(key);
// same pattern with getString / getInt / getDouble
```

### 9. Crash reports
Inside the app's crash-reporter wrapper (Crashlytics, Sentry, …), alongside
the real upstream call:
```dart
DebugLens.instance.recordCrash(DebugLensCrashEvent(
  error: error, stackTrace: stackTrace, fatal: fatal,
  reason: reason, customData: customData ?? const {},
));
```
If uncaught errors bypass the wrapper (a global handler reports them
directly), add the same call in that handler too — but make sure each error is
recorded exactly once.

### 10. Analytics
Inside the analytics wrapper, alongside each real send:
```dart
DebugLens.instance.recordAnalyticsEvent(eventName, parameters: params);
```
If the analytics layer has an "event logged" hook/callback, prefer wiring it
there once over touching each call site.

### 11. Performance
Wherever the app stops a timed operation (you own the stopwatch — DebugLens
records finished traces only):
```dart
DebugLens.instance.recordTrace('home_load', stopwatch.elapsed);
```

### 12. App version
At startup, after reading the real version (e.g. `package_info_plus`) —
**awaited, once**:
```dart
await DebugLens.instance.setAppVersion(packageInfo.version);
```
Then have version displays/reports read `DebugLens.instance.appVersion` so a
panel override (applied on next launch) flows through automatically.

### 13. Custom error screen
In `main()`, before `runApp`:
```dart
ErrorWidget.builder = (details) => CustomErrorScreen(details: details);
```

## Step 5 — Verify

- Run `flutter analyze` (or ask the user to) and fix any issue you introduced.
- Ask the user to run the app: a draggable bubble should appear; tapping it
  opens the DebugLens dashboard, and each integrated inspector should show
  live data as they use the app.

## Step 6 — Report, then offer the rest

Summarize exactly what you changed, file by file. Then tell the user:

> DebugLens has more than what we just wired, all addable later without
> reworking anything done today: per-tab observers for nested navigators
> (`DebugLens.newNavigatorObserver(label: …)` + `detach()` on dispose),
> tester/developer roles with per-screen access you can seed from code
> (`initialRole`, `initialTesterAccess`, `initialTesterEnabled`), per-feed
> retention limits (`DebugLens.initialLimits`), custom service inspectors for
> anything else (`DebugLensService` + `registerService`), Dio capture options
> (disable body capture, header redaction via
> `DebugLensDioInterceptorSettings`), forwarding captured logs elsewhere
> (`DebugLensLogger().addLogObserver`), and an in-panel health-check report
> that needs no wiring at all. Ask your AI assistant to integrate any of these
> whenever you need them — it can read the package source in your pub cache
> for the details.

Rules you must follow throughout:
- Never gate DebugLens calls behind your own `if` checks — the master switch already no-ops everything when disabled.
- Never touch members marked `@internal` (e.g. the logger's `maxHistory`, `isCapturing`).
- Match the project's existing style, naming and file layout; put each integration in the class that owns that concern.
- Do not add dependencies the project doesn't already have (other than `debug_lens` itself).
- Never upgrade, downgrade, or override the project's existing dependency versions without naming the exact change and getting the user's explicit yes first.
