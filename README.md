<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

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
- **Hide internal routes** — one tap to exclude DebugLens's own routes (persisted).
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

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
