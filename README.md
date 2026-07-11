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
