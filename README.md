# DebugLens

**DebugLens** is an on-device debugging tool for your Flutter projects. It gives you 
visibility into what's happening inside your app by bringing together all the important 
runtime information in one place, network calls, logs, bloc transitions, navigation, storage,
device facts, crashes, analytics and remote config — all in one place, on the
device. You don't have to reproduce a bug or walk through the steps to get
back to the state something failed in; the current state is just there, which
saves you the time.

Whether you're a developer, a tester, or on the product side, DebugLens helps you 
identify problems faster. Any inspector's data can be shared on its own,
including straight into an AI tool, for faster debugging. Nothing it captures
is saved anywhere but the device.

## Install

```yaml
dependencies:
  debug_lens: ^0.0.1
```

| Dashboard | Bubble |
| :-: | :-: |
| <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/dashboard.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/settings_bubble.png" width="240"> |

## Setup

Wrap your app and attach the navigator observer. Everything else is opt-in, one
inspector at a time.

```dart
// The observer feeds Navigation; wrap mounts the bubble and the panel itself.
MaterialApp(
  navigatorObservers: [DebugLens.navigatorObserver],
  builder: (context, child) => DebugLens.wrap(child ?? const SizedBox.shrink()),
);
```

`DebugLens.debugLensEnabled` determines whether DebugLens is enabled. It defaults to **`true`**.
When set to `false`, `wrap` becomes a no-op: nothing is captured, and no overrides are applied. 
Set this value in `main()` before `wrap` is first built, and base it on your own flavor or build 
configuration to control who can use DebugLens.


```dart
void main() {
  DebugLens.debugLensEnabled = !kReleaseMode;   // or: flavor != Flavor.production
  runApp(const MyApp());
}
```

---

## Inspectors

### Network

Every Dio request and response is captured automatically, including its headers, body, status code, 
and duration, without requiring a proxy or any additional tools. Requests are grouped by endpoint into
a timeline, making it easy to spot patterns. Whether the same request is being sent multiple times, an 
endpoint is polling more often than expected, or multiple user actions trigger identical calls, these 
issues become immediately visible instead of being buried in individual log entries. The connectivity 
indicator in the AppBar also lets you quickly tell whether a failed or delayed request is caused by 
the device's network connection or by the backend.


```dart
// Captures every request/response this Dio instance makes.
dio.interceptors.add(DebugLensDioInterceptor());
```

| Network calls | Call detail | Per-endpoint history | Call timeline |
| :-: | :-: | :-: | :-: |
| <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/network_list.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/network_detail.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/network_history.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/network_history_detail.png" width="240"> |

### Logs

View all your app logs in a single timeline, including your own logs sent through DebugLensLogger() and 
logs captured automatically by DebugLens. Each log source(network, bloc, navigation etc) can be enabled or 
disabled independently, making it easy to focus on the information you need while debugging.

To capture your existing print() or debugPrint() output, override them once in your app to use DebugLensLogger(). 
This lets you see your console logs directly inside DebugLens without changing the rest of your logging code.

Use `DebugLensLogger()` to send logs from anywhere in your app:

```dart
// Optional: Disable terminal output while keeping logs in DebugLens.
DebugLensLogger().printToConsole = kDebugMode;

DebugLensLogger().i('Signed in', name: 'auth');
DebugLensLogger().e('Upload failed', name: 'media', error: e, stackTrace: s);
```

You can also configure retention limits to control how many logs and other captured records DebugLens keeps in memory during a session.

```dart
// Seeds the buffer size; a tester can still raise or lower it from Settings.
DebugLens.initialLimits = const DebugLensLimits(logs: 5000, network: 1000);
```

| Feed | Default | Field |
| --- | :-: | --- |
| Network | 250 | `network` |
| Logs | 1000 | `logs` |
| Notifications | 200 | `notifications` |
| Deep-links | 200 | `deeplinks` |
| Bloc | 200 | `bloc` |
| Navigation | 500 | `navigation` |
| Crashes | 100 | `crashes` |
| Analytics | 100 | `analytics` |
| Traces | 100 | `traces` |

Every field accepts 50–5000; a value outside that range is ignored and the
default applies. Like the role and its grants, this seeds the **first launch
only** — a limit edited from Settings afterwards wins from then on.

| Logs | Capture switches |
| :-: | :-: |
| <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/logs.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/logs_capture.png" width="240"> |

### Bloc

Every BLoC and Cubit lifecycle event is recorded automatically once `Bloc.observer` is set. 
This includes when a bloc is created, an event is received, a state changes, an error occurs, 
and when the bloc is closed. No per-bloc setup is required. When someone reports that 
"the UI didn't update," you can quickly see what actually happened. Did the event reach the bloc? 
Did the state change? Or did the widget simply not rebuild? If a single user action causes multiple 
state transitions, you'll see them in the exact order they occurred, making it much easier to 
understand and debug your app's behavior.


```dart
// One line covers every bloc and cubit in the app.
Bloc.observer = DebugLensBlocObserver();
```

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/bloc.png" width="240">

### Navigation

Every navigation event is recorded, including route pushes, pops, and replacements, 
while maintaining a live view of the navigator stack. This makes it easy to see exactly 
how a user reached the current screen. Whether a route was pushed twice because of a fast 
double tap, a back button closed the wrong screen, or navigation didn't behave as expected, 
you can trace the complete sequence of events instead of guessing from the UI. If your 
app uses nested navigators, such as bottom navigation tabs or shell routes, each navigator 
has its own labeled stack, making it easy to identify navigation issues without mixing them up.


```dart
// Root navigator — see Setup above.
navigatorObservers: [DebugLens.navigatorObserver],

// A nested navigator, e.g. one tab of a shell.
final observer = DebugLens.newNavigatorObserver(label: 'home');
```

| Route events | Navigator stack |
| :-: | :-: |
| <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/navigation_events.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/navigation_stack.png" width="240"> |

### Storage

View your app's **SharedPreferences** and database tables directly from DebugLens through 
a storage adapter that you provide. DebugLens reads the data only when requested, never 
stores a copy, and doesn't depend on your storage library. When debugging, you can immediately 
verify what's actually stored on the device. Is a feature flag persisted? Did a database 
migration run successfully? Is the expected row still present? The data you see is always 
the current state on disk, not a snapshot taken when the panel was opened.


```dart
// Called on demand, so this always reflects what's on disk right now.
DebugLens.sharedPrefsSource = () => [
  for (final key in prefs.getKeys())
    DebugLensPrefEntry(key: key, value: '${prefs.get(key)}'),
];

DebugLens.registerDatabase(MyDriftAdapter(db));
```

| SharedPreferences | Database |
| :-: | :-: |
| <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/storage_prefs.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/storage_database.png" width="240"> |

### Locale

Displays your app's currently active localization strings, making it easy to verify the exact 
values being shown to users. Missing translations, incorrect keys, or fallback values are immediately 
visible without relying on screenshots or user reports. The localization data is read live, so changing 
the app's language updates the view instantly. This makes it easy to reproduce and debug localization 
issues without restarting the app for every language change.


```dart
// Read live on every build, so a language switch updates the screen instantly.
DebugLens.localeSource = () => DebugLensLocaleData(
  entries: currentLangMap,
  label: 'English',
);
```

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/locale.png" width="240">

### Notifications & deep-links

Two dedicated tabs let you inspect **Notifications** and **Deep Links**. View every notification 
your app receives or displays along with its raw payload, and inspect every deep link with its 
scheme, host, path, and query parameters. When something doesn't behave as expected, you can 
quickly see what happened. Was the notification payload incorrect? Did the deep link resolve 
to the expected route? Or did the navigation fail after the link was parsed? Having all this 
information in one place makes notification and deep-link issues much easier to debug.


```dart
// Call on display and again on tap, so both show up as separate entries.
DebugLens.recordNotification(
  title: message.title,
  body: message.body,
  payload: message.data,
  source: 'FCM',
);

DebugLens.recordDeeplink(uri.toString(), source: 'os');
```

| Notifications | Deep-links |
| :-: | :-: |
| <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/notifications.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/deeplinks.png" width="240"> |

### Services

A screen of your own for anything DebugLens doesn't already model. Write an
adapter when the source can be read back on demand, a cache, a feature-flag
client, a queue; push into one of the four built-ins below (remote config,
crashes, analytics, traces) when it can't. Either way it's an inspector you
define, not a fixed list DebugLens ships with.

```dart
// load() is called on demand, not cached, so it's always the live source.
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

### Remote config

Shows every value fetched from your remote config provider and lets a device
override any of them independently of what the backend actually sent. That's
how a flag-gated bug gets reproduced without waiting on a config rollout or
fighting the provider's own targeting rules: the override applies locally on
the next launch, and the resolved getters (`getBool`, `getInt`, ...) always
reflect it.

```dart
// Await once at startup — this loads any override saved on a previous run.
await DebugLens.instance.setRemoteConfigData({
  for (final e in firebase.getAll().entries) e.key: e.value.asString(),
}, sourceLabel: 'Firebase');

final timeout = DebugLens.instance.getInt('api_timeout_seconds');
```

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/remote_config.png" width="240">

### Crash reports

Crash reporters are write-only by design, so DebugLens keeps the same payload
you send upstream, stack trace included, right on the device that produced it.
Reproducing a crash and reading its stack trace no longer waits on Crashlytics
to finish processing the event, or on a tester remembering exactly what they
tapped.

```dart
// Hand it the exact payload your crash reporter sends upstream.
DebugLens.instance.initCrashReporting();

DebugLens.instance.recordCrash(
  DebugLensCrashEvent(error: error, stackTrace: stack, fatal: false),
);
```

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/services_crashlytics.png" width="240">

### Analytics

Every event you log appears as its own row the moment you call it, with its
parameters visible on expand. It answers a specific question during a manual
test pass: did this action actually fire the event you expect, with the fields
you expect, without waiting hours for it to land in a dashboard.

```dart
// The name becomes the row; parameters show when it's expanded.
DebugLens.instance.initAnalytics();

DebugLens.instance.recordAnalyticsEvent(
  'add_to_cart',
  parameters: {'sku': sku, 'price': price},
);
```

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/services_analytics.png" width="240">

### Performance

Finished traces show up with their duration and whatever attributes you
attached when the trace stopped. Since you own the running stopwatch, this is
how you eyeball whether a screen's load time regressed on this exact device
and build, without a performance-monitoring dashboard catching up later.

```dart
// You own the stopwatch; push once when the trace stops.
DebugLens.instance.initPerformance();

DebugLens.instance.recordTrace('home_load', stopwatch.elapsed);
```

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/services_performance.png" width="240">

### Device & app

View important information about the current device and app, including the device model, 
manufacturer, OS version, screen size, app version, and current network connection. This 
information is collected automatically, with no additional setup required. When investigating 
a bug, you can immediately see the environment in which it occurred without asking the user 
for device details.

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/device.png" width="240">

### App version

Override the app version reported by your application to test version-dependent behavior 
without rebuilding your app. This is useful for testing feature flags, minimum version 
checks, force updates, or any logic that depends on the app version. The overridden version is 
applied on the next app launch, and your app continues to read the version using the same API.

```dart
// Await once at startup — this loads any override saved on a previous run.
await DebugLens.instance.setAppVersion(packageInfo.version);

// Read it back wherever the app shows or reports its version.
Text(DebugLens.instance.appVersion);
```

### Custom error screen

Replace Flutter's default red error screen with a cleaner, more readable error page. It 
displays the exception and full stack trace, both of which can be copied and shared easily. 
This makes it much easier for testers to report build errors without relying on screenshots.

```dart
// Replaces Flutter's default red error box wherever a widget fails to build.
ErrorWidget.builder = (details) => CustomErrorScreen(details: details);
```

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/custom_error_screen.png" width="240">

### Health check

Start a **Health Check** session from **Settings** before testing a feature, running 
regression tests, or reproducing an issue. When you're finished, stop the session and DebugLens 
generates a single report containing all crashes and error logs captured during that period, 
making it easy to understand what happened without manually collecting logs.


<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/health_report.png" width="240">

### Roles

DebugLens supports Developer and Tester roles. Developers have access to every screen, 
while testers can only access the screens that have been explicitly allowed. This lets you 
safely include DebugLens in QA builds without exposing sensitive tools or configuration screens.
You can configure the default role and tester permissions in code:

```dart
DebugLens.initialRole = DebugRole.developer;      // default: tester
DebugLens.initialTesterAccess = {                 // default: {network}
  DebugScreen.network,
  DebugScreen.logs,
  DebugScreen.device,
};
DebugLens.initialTesterEnabled = false;           // default: true
```

These values are applied only on the first app launch. After that, any changes made from 
Settings are preserved and won't be overwritten by future app updates. Configure them before
DebugLens.wrap is first built. DebugScreen includes every DebugLens screen except Settings, 
since allowing testers to access Settings would let them modify their own permissions.

| Settings | Role picker | Tester access |
| :-: | :-: | :-: |
| <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/settings.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/settings_role.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/settings_tester_access.png" width="240"> |

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/role_switch.png" width="240">

---

## Credits

The Dash artwork bundled as one of the bubble icons
(`assets/dash.png`) is part of the Flutter brand assets, © Google, used under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Flutter and the
Flutter logo are trademarks of Google LLC.

## License

[MIT](LICENSE)
