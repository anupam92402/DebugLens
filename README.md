# DebugLens

An in-app debugging overlay for Flutter. A draggable bubble opens a panel that
shows what your app is actually doing — network calls, logs, bloc transitions,
navigation, storage, device facts and your backend SDKs — on the device, with no
console attached and no laptop in the room.

It is built for the people who don't have your IDE open: QA on a test build, a
teammate reproducing a bug, you on a phone that isn't plugged in. Every
inspector is wired to your own app through a small seam, so DebugLens depends on
none of your vendors and drops out cleanly when you remove it.

## Screenshots

| Dashboard | Network | Logs |
| :-: | :-: | :-: |
| <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/dashboard.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/network.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/logs.png" width="240"> |

| Remote config | Settings |
| :-: | :-: |
| <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/remote_config.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/settings.png" width="240"> |

## Install

```yaml
dependencies:
  debug_lens: ^1.0.0
```

## Setup

Wrap your app and attach the navigator observer. Everything else is opt-in, one
inspector at a time.

```dart
MaterialApp(
  navigatorObservers: [DebugLens.navigatorObserver],
  builder: (context, child) => DebugLens.wrap(child ?? const SizedBox.shrink()),
);
```

Implementation: [debug_lens.dart](lib/debug_lens.dart) · Example:
[app.dart](example/lib/src/app.dart)

---

## Inspectors

### Network

Captures every Dio request and response — headers, bodies, status, duration —
and keeps a per-endpoint call history for the session. A connectivity indicator
in the AppBar shows the device's current transport.

```dart
dio.interceptors.add(DebugLensDioInterceptor());
```

Implementation:
[debug_lens_dio_interceptor.dart](lib/src/features/network/data/debug_lens_dio_interceptor.dart)
· Example:
[api_service.dart](example/lib/src/features/network_demo/data/api_service.dart)

### Logs

A level-tagged log feed you write to instead of `print`. Each source can be
muted from the panel, so a chatty origin stops filling the feed without a code
change.

```dart
final log = DebugLensLogger.instance..printToConsole = kDebugMode;

log.i('Signed in', name: 'auth');
log.e('Upload failed', name: 'media', error: e, stackTrace: s);
```

Implementation:
[debug_lens_logger.dart](lib/src/features/logs/data/debug_lens_logger.dart) ·
Example: [app_log.dart](example/lib/src/core/logging/app_log.dart)

### Bloc

Records every bloc and cubit lifecycle event — created, event received, state
transition, error, closed. One line, and every bloc in the app is covered.

```dart
Bloc.observer = DebugLensBlocObserver();
```

Implementation:
[debug_lens_bloc_observer.dart](lib/src/features/bloc/data/debug_lens_bloc_observer.dart)
· Example: [main.dart](example/lib/main.dart)

### Navigation

A log of every route push, pop and replace, plus a live view of the navigator
stack. Nested navigators get their own labelled stack.

```dart
// Root navigator — see Setup above.
navigatorObservers: [DebugLens.navigatorObserver],

// A nested navigator, e.g. one tab of a shell.
final observer = DebugLens.newNavigatorObserver(label: 'home');
```

Implementation:
[debug_lens_navigator_observer.dart](lib/src/features/navigation/data/debug_lens_navigator_observer.dart)
· Example:
[tab_navigator.dart](example/lib/src/features/shell/presentation/widgets/tab_navigator.dart)

### Storage

Shows the app's SharedPreferences and its database tables. Both are read on
demand through an adapter you supply, so DebugLens never holds a copy and never
imports your storage package.

```dart
DebugLens.sharedPrefsSource = () => [
  for (final key in prefs.getKeys())
    DebugLensPrefEntry(key: key, value: '${prefs.get(key)}'),
];

DebugLens.registerDatabase(MyDriftAdapter(db));
```

Implementation:
[debug_shared_prefs_source.dart](lib/src/features/storage/data/debug_shared_prefs_source.dart),
[debug_database_source.dart](lib/src/features/storage/data/debug_database_source.dart)
· Example: [prefs_bridge.dart](example/lib/src/core/storage/prefs_bridge.dart),
[drift_debug_lens_adapter.dart](example/lib/src/core/storage/drift_debug_lens_adapter.dart)

### Locale

Renders the app's active string map so a missing or wrong translation is visible
on the device. Read live on every build, so switching language updates it.

```dart
DebugLens.localeSource = () => DebugLensLocaleData(
  entries: currentLangMap,
  label: 'English',
);
```

Implementation:
[debug_locale_source.dart](lib/src/features/locale/data/debug_locale_source.dart)
· Example: [service_locator.dart](example/lib/src/core/di/service_locator.dart)

### Notifications & deep-links

Two tabs: the notifications your app shows or handles with their raw payloads,
and the deep-links it opens, broken into scheme, host, path and query.

```dart
DebugLens.recordNotification(
  title: message.title,
  body: message.body,
  payload: message.data,
  source: 'FCM',
);

DebugLens.recordDeeplink(uri.toString(), source: 'os');
```

Implementation:
[notification_entry.dart](lib/src/features/notifications/domain/notification_entry.dart)
· Example:
[notification_service.dart](example/lib/src/core/notifications/notification_service.dart)

### Services

Anything else your app talks to, as its own screen. Write an adapter when the
source can be read back; push into one of the four built-ins below when it
can't.

```dart
class CacheInspector extends DebugLensService {
  @override
  String get name => 'API cache';

  @override
  Future<List<DebugLensServiceGroup>> load() async => [
    for (final e in myCache.entries)
      DebugLensServiceGroup(title: e.key, values: {'size': '${e.bytes} B'}),
  ];
}

DebugLens.registerService(CacheInspector());
```

Implementation:
[debug_service_source.dart](lib/src/features/services/data/debug_service_source.dart)
· Example:
[mock_firebase.dart](example/lib/src/core/firebase/mock_firebase.dart)

### Remote config

Share the values you fetched and override any of them on the device. DebugLens
owns the override storage and the source/custom switch; overrides apply on the
next app start.

```dart
await DebugLens.instance.setRemoteConfigData({
  for (final e in firebase.getAll().entries) e.key: e.value.asString(),
}, sourceLabel: 'Firebase');

final timeout = DebugLens.instance.getInt('api_timeout_seconds');
```

Implementation:
[debug_config_store.dart](lib/src/features/services/data/debug_config_store.dart)
· Example:
[mock_remote_config.dart](example/lib/src/core/firebase/mock_remote_config.dart)

### Crash reports

Crash reporters are write-only, so hand DebugLens the same payload you send
upstream. The report stays on the device that produced it, stack trace included.

```dart
DebugLens.instance.initCrashReporting();

DebugLens.instance.recordCrash(
  DebugLensCrashEvent(error: error, stackTrace: stack, fatal: false),
);
```

Implementation:
[debug_crash_store.dart](lib/src/features/services/data/debug_crash_store.dart)
· Example:
[mock_crashlytics.dart](example/lib/src/core/firebase/mock_crashlytics.dart)

### Analytics

The events you log, as you log them. The name is the row; everything else goes
in the parameter map and shows when the row is expanded.

```dart
DebugLens.instance.initAnalytics();

DebugLens.instance.recordAnalyticsEvent(
  'add_to_cart',
  parameters: {'sku': sku, 'price': price},
);
```

Implementation:
[debug_analytics_store.dart](lib/src/features/services/data/debug_analytics_store.dart)
· Example: [mock_analytics.dart](example/lib/src/core/firebase/mock_analytics.dart)

### Performance

Finished traces with their durations. You keep the running trace — the stopwatch
and its attributes — and push once when it stops.

```dart
DebugLens.instance.initPerformance();

DebugLens.instance.recordTrace('home_load', stopwatch.elapsed);
```

Implementation:
[debug_trace_store.dart](lib/src/features/services/data/debug_trace_store.dart)
· Example:
[mock_performance.dart](example/lib/src/core/firebase/mock_performance.dart)

### Device & app

Model, manufacturer, OS, screen metrics and the active network transport,
gathered once per run. No wiring — it reads the platform directly.

Implementation:
[device_info_source.dart](lib/src/features/device/data/device_info_source.dart)

### App version

Override the version string your app reports, so you can reproduce
version-gated behaviour without a rebuild. Applies on the next app start.

```dart
await DebugLens.instance.setAppVersion(packageInfo.version);

// Read it back wherever the app shows or reports its version.
Text(DebugLens.instance.appVersion);
```

Implementation:
[app_version_store.dart](lib/src/features/settings/data/app_version_store.dart)
· Example: [main.dart](example/lib/main.dart)

### Custom error screen

Replaces Flutter's red error box with a readable one showing the exception and
stack trace, each copyable straight into a share sheet. You install it, so your
own error handling stays in charge.

```dart
ErrorWidget.builder = (details) => CustomErrorScreen(details: details);
```

Implementation:
[custom_error_screen.dart](lib/src/features/error/presentation/views/custom_error_screen.dart)
· Example: [main.dart](example/lib/main.dart)

### Health check

Start a window from Settings, reproduce the problem, stop it, and get a report
of every crash and error log in between. No wiring — it reads the feeds above.

Implementation:
[health_check_store.dart](lib/src/features/health/data/health_check_store.dart)

### Roles

Developer mode sees every screen; tester mode sees only what a developer has
granted. Tap the role chip beside the dashboard title to switch. No wiring —
configure the grants from Settings.

Implementation: [debug_role.dart](lib/src/core/debug_role.dart)

---

## Contributing

Issues and pull requests are welcome at
[github.com/anupam92402/DebugLens](https://github.com/anupam92402/DebugLens).

### Before you open a PR

* **Open an issue first** for anything beyond a bug fix. A new inspector or a
  change to a public API is worth agreeing on before it is written.
* **Branch from `master`** and keep the branch to one concern. A PR that fixes a
  bug and renames three files is two PRs.
* **`flutter analyze` must be clean** and `dart format .` must leave no diff.
  Both run on the package and on `example/`.
* **Try it in the example app.** `cd example && flutter run`. If your change has
  no visible effect there, say in the PR how you verified it.

### What a good PR looks like

* **A title that says what changed**, not which files moved — "cap analytics
  events at the configured limit", not "update store".
* **A description that explains why**, and how you tested it. Screenshots for
  anything visual; the panel is a UI.
* **No new dependency** without a note on why the existing ones don't cover it.
  DebugLens stays vendor-neutral: it must not import Firebase, Sentry, or any
  other SDK a host might swap out.
* **Comments that explain the reasoning**, not the syntax. Match the density of
  the file you are editing.
* **A CHANGELOG entry** under an `## Unreleased` heading for anything a user
  would notice.

### Conventions worth knowing

* User-facing copy lives in
  [debug_strings.dart](lib/src/shared/debug_strings.dart); non-display constants
  and preference keys live in
  [debug_constants.dart](lib/src/shared/debug_constants.dart).
* Features follow `data/`, `domain/`, `presentation/views/`,
  `presentation/widgets/`. Screens go in `views/`, everything else in
  `widgets/`.
* Reuse the shared widget kit in
  [shared/widgets](lib/src/shared/widgets) before adding a new widget — most
  layouts already have one.
* The panel keeps no copy of data it can ask the host for. If your inspector can
  read live, give it a source rather than a store.

## Credits

The Dash artwork bundled as one of the bubble icons
(`assets/dash.png`) is part of the Flutter brand assets, © Google, used under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Flutter and the
Flutter logo are trademarks of Google LLC.

## License

[MIT](LICENSE)
