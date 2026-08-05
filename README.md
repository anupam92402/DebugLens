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

## Setup

| Dashboard | Bubble |
| :-: | :-: |
| <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/dashboard.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/settings_bubble.png" width="240"> |

Wrap your app and attach the navigator observer. Everything else is opt-in, one
inspector at a time.

```dart
// The observer feeds Navigation; wrap mounts the bubble and the panel itself.
MaterialApp(
  navigatorObservers: [DebugLens.navigatorObserver],
  builder: (context, child) => DebugLens.wrap(child ?? const SizedBox.shrink()),
);
```

`DebugLens.debugLensEnabled` decides whether any of this runs at all —
defaults to **true**. Off, `wrap` is a no-op: nothing is captured, no
overrides apply. Set it in `main`, before `wrap` first builds, and base it on
your own flavor flag rather than `kReleaseMode` — a QA build is usually a
release build, exactly when a tester needs the panel.

```dart
void main() {
  DebugLens.debugLensEnabled = !kReleaseMode;   // or: flavor != Flavor.production
  runApp(const MyApp());
}
```

---

## Inspectors

### Network

Every Dio request and response is captured in full: headers, body, status and
duration, with no proxy or extra tooling attached to the device. Calls are
grouped per endpoint into a running history, so a duplicate call firing off the
same screen, a request repeating on an interval it shouldn't be polling on, or
two taps racing to hit the same endpoint all surface as a visible pattern rather
than a single log line. The connectivity indicator in the AppBar tells you
upfront whether a stalled call is a transport problem or a backend one.

```dart
// Captures every request/response this Dio instance makes.
dio.interceptors.add(DebugLensDioInterceptor());
```

| Network calls | Call detail | Per-endpoint history | Call timeline |
| :-: | :-: | :-: | :-: |
| <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/network_list.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/network_detail.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/network_history.png" width="240"> | <img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/network_history_detail.png" width="240"> |

### Logs

A single feed for everything the app says, replacing scattered `print` calls
with one tagged timeline that lives on the device instead of a terminal. Each
source, your own calls as well as DebugLens's own instrumentation, can be muted
independently from the panel, so isolating one subsystem during a repro doesn't
need a code change. Every push API (crash, analytics, trace, notification)
mirrors into this same feed, so correlating an error against what led up to it
is one list to scroll instead of four to cross-reference.

```dart
// Mute the terminal echo once you trust the panel; records still land here.
DebugLensLogger().printToConsole = kDebugMode;

DebugLensLogger().i('Signed in', name: 'auth');
DebugLensLogger().e('Upload failed', name: 'media', error: e, stackTrace: s);
```

`DebugLensLogger()` constructs nothing — it hands back the one logger the panel
reads, so there is no global to import and no instance to hold. Don't dispose it:
it is a `ChangeNotifier` the Logs screen listens to.

#### Retention limits

Every captured feed, logs included, keeps a fixed number of records before the
oldest ones drop, so a long session doesn't hold an unbounded amount of bodies
and stack traces in memory. `DebugLensLimits` sets these per feed in one
object; a feed left `null` keeps its shipped default.

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

Every bloc and cubit lifecycle event, created, event received, state
transition, error, closed, is recorded the moment `Bloc.observer` is set, with
no per-bloc wiring. An intermittent "the UI didn't update" report becomes a
direct comparison instead of a guess: did the event reach the bloc, did the
state actually change, or did the widget just not rebuild. A state that flips
twice for one user action shows up here as two transitions back to back.

```dart
// One line covers every bloc and cubit in the app.
Bloc.observer = DebugLensBlocObserver();
```

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/bloc.png" width="240">

### Navigation

Records every route push, pop and replace, and keeps a live view of the
navigator stack. A back button that closes the wrong screen, or a route
pushed twice under a fast double-tap, shows up here as an actual sequence of
events instead of something inferred from watching the screen. Nested
navigators, a bottom-nav tab, a shell route, get their own labelled stack, so a
leak in one tab's history is never confused with another's.

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

Shows the app's SharedPreferences and its database tables, both read on demand
through an adapter you supply, so DebugLens never holds a copy and never
imports your storage package. A "stale value after the fix shipped" report
becomes answerable on the device itself: is the flag actually persisted, did
the migration run, is the row still there. What's on screen is what's on disk
right now, not a snapshot from when the panel opened.

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

Renders the app's currently active string map, so a missing key or an
untranslated fallback is visible on the device instead of reported secondhand
from a screenshot. It's read live on every build, so switching the app's
language mid-session updates the screen immediately, turning a locale-switch
bug into something reproducible in seconds rather than a restart per language.

```dart
// Read live on every build, so a language switch updates the screen instantly.
DebugLens.localeSource = () => DebugLensLocaleData(
  entries: currentLangMap,
  label: 'English',
);
```

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/locale.png" width="240">

### Notifications & deep-links

Two tabs: every notification the app shows or handles, with its raw payload,
and every deep-link it opens, broken into scheme, host, path and query. This is
what turns "the push arrived but nothing happened" into a diagnosable case: did
the payload look wrong, did the link parse into the route you expected, or did
navigation just not follow through.

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

Model, manufacturer, OS version, screen metrics and the current network
transport, gathered once per run with no wiring required. It exists for the
one question every bug report needs answered first: what device, what OS, what
build was this actually seen on.

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/device.png" width="240">

### App version

Overrides the version string the app reports, so version-gated behaviour, a
feature flag tied to a minimum version, a forced-update check, can be
reproduced on a device without rebuilding at that version. The override
applies from the next app start, and reading it back is the same call your app
already uses to display or report its version.

```dart
// Await once at startup — this loads any override saved on a previous run.
await DebugLens.instance.setAppVersion(packageInfo.version);

// Read it back wherever the app shows or reports its version.
Text(DebugLens.instance.appVersion);
```

### Custom error screen

Replaces Flutter's red error box with a readable one built for handing off: the
exception and its full stack trace are both there, and both copyable straight
into a share sheet. A tester who hits a build error can now send you the actual
stack trace instead of a screenshot of a wall of red text.

```dart
// Replaces Flutter's default red error box wherever a widget fails to build.
ErrorWidget.builder = (details) => CustomErrorScreen(details: details);
```

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/custom_error_screen.png" width="240">

### Health check

Start a window from Settings, reproduce the problem, stop it, and get back
every crash and error log recorded in between as a single report. It exists
for the reports that start with "something went wrong somewhere in the last
few minutes": instead of asking someone to describe what happened, you get the
log.

<img src="https://raw.githubusercontent.com/anupam92402/DebugLens/master/doc/screenshots/health_report.png" width="240">

### Roles

Developer mode sees every screen; tester mode sees only what a developer has
explicitly granted, configured from Settings. This is what makes it safe to
hand the panel to a QA build: a tester can't wander into Remote config and edit
values meant for someone else, and what they can see is a decision made in
code, not whatever they discover by tapping around.

Both the starting role and what a tester may open can be set from code, so a QA
build arrives configured instead of needing boxes ticked on the device:

```dart
DebugLens.initialRole = DebugRole.developer;      // default: tester
DebugLens.initialTesterAccess = {                 // default: {network}
  DebugScreen.network,
  DebugScreen.logs,
  DebugScreen.device,
};
DebugLens.initialTesterEnabled = false;           // default: true
```

All three seed the **first launch only**. Once the role has been switched or the
grants edited from Settings on a device, that choice wins — so changing these in
a later release never overrides what someone picked. Set them before `wrap`
first builds.

`DebugScreen` covers every panel screen except Settings, which can't be granted:
it is where access is configured, so a tester with it could widen their own.

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
