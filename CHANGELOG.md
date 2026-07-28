# Changelog

## 1.0.0

First public release. DebugLens is an in-app debugging overlay: a draggable
bubble opens a panel that inspects what your app is doing, on the device, with
no console attached.

* **`DebugLens.debugLensEnabled`** — one switch for the whole package. Off means `wrap`
  returns your app untouched, every capture path no-ops, and no override is
  applied. Defaults to on; gating release builds is the host's call.
* **Network** — every Dio request and response with headers, bodies, timings and
  status, plus per-endpoint call history and a live connectivity indicator.
* **Logs** — a level-tagged log feed with per-source capture switches, so you can
  mute a noisy origin without touching code.
* **Bloc** — every bloc and cubit lifecycle event: creation, events, state
  transitions, errors and closure.
* **Navigation** — a route event log and a live navigator stack, including
  nested navigators.
* **Storage** — the app's SharedPreferences and database tables, read live from
  the host through a small adapter.
* **Locale** — the app's active string map, searchable and paged, for spotting a
  missing or wrong translation.
* **Notifications & deep-links** — push and local notifications with their
  payloads, and captured deep-links broken into scheme, host, path and query.
* **Device & app** — model, OS, screen metrics, locale and network transport,
  gathered once per run from the platform.
* **Services** — backend and SDK data as a list of screens. Write an adapter for
  anything readable, or push into one of the four built-ins.
* **Remote config** — share your fetched values and override any of them on the
  device; overrides persist and apply on the next app start.
* **Crash reports** — every error your reporter sends, kept on the device that
  produced it, with the stack trace one tap from a share sheet.
* **Analytics** — the events you log, with their parameters, as they are sent.
* **Performance** — finished traces with their durations and attributes.
* **Custom error screen** — a readable, copyable replacement for Flutter's red
  error box, installed from your own `ErrorWidget.builder`.
* **Health check** — start a window, reproduce a problem, stop it, and get a
  shareable report of every crash and error log in between.
* **Roles** — a developer mode that sees everything and a tester mode limited to
  the screens you grant, switched from a chip beside the dashboard title.
  `DebugLens.initialRole`, `initialTesterAccess` and `initialTesterEnabled`
  configure a fresh install from code, so a QA build ships ready.
* **First-run walkthrough** — a three-step tour of the dashboard, the role chip
  and getting back to the app, shown once per install.
* **Settings** — reorder the dashboard, restyle and reposition the bubble, set
  per-feed retention limits, override the app version, and clear all captured
  data.
