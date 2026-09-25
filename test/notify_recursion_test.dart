import 'package:debug_lens/debug_lens.dart';
import 'package:debug_lens/src/core/debug_store.dart';
import 'package:debug_lens/src/features/services/data/debug_analytics_store.dart';
import 'package:debug_lens/src/features/services/data/debug_crash_store.dart';
import 'package:debug_lens/src/features/services/data/debug_service_source.dart';
import 'package:debug_lens/src/features/services/data/debug_trace_store.dart';
import 'package:debug_lens/src/features/bloc/domain/bloc_event.dart';
import 'package:debug_lens/src/features/navigation/domain/nav_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DebugLens.debugLensEnabled = true;
    DebugLens.initialLimits = const DebugLensLimits.all(50);
    DebugLensLogger().printToConsole = false;
    DebugStore.instance.clearAll();
  });

  test('a record does not notify synchronously', () async {
    var notifications = 0;
    void listener() => notifications++;
    DebugLensLogger().addListener(listener);
    addTearDown(() => DebugLensLogger().removeListener(listener));

    DebugLensLogger().d('one');
    DebugLensLogger().d('two');
    DebugLensLogger().d('three');
    expect(
      notifications,
      0,
      reason: 'notifying inline reaches markNeedsBuild during a build',
    );

    await Future<void>.delayed(Duration.zero);
    expect(notifications, 1, reason: 'a burst collapses into one rebuild');
  });

  test('a log emitted from inside the logger never recurses', () async {
    var depth = 0;
    var maxDepth = 0;
    var reentries = 0;
    void listener() {
      depth++;
      maxDepth = depth > maxDepth ? depth : maxDepth;
      // A host whose FlutterError.onError records into DebugLens does exactly
      // this. Bounded here so the test cannot livelock on a listener that
      // always logs — what matters is that no call nests inside another.
      if (reentries++ < 5) DebugLensLogger().e('from inside a notification');
      depth--;
    }

    DebugLensLogger().addListener(listener);
    addTearDown(() => DebugLensLogger().removeListener(listener));

    DebugLensLogger().d('kick off');
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(maxDepth, 1, reason: 'notifications must never nest');
    expect(DebugLensLogger().history.length, lessThanOrEqualTo(50));
  });

  test('no capture path signals its screen synchronously', () async {
    var crash = 0, analytics = 0, trace = 0, registry = 0;
    void onCrash() => crash++;
    void onAnalytics() => analytics++;
    void onTrace() => trace++;
    void onRegistry() => registry++;
    DebugCrashStore.instance.revision.addListener(onCrash);
    DebugAnalyticsStore.instance.revision.addListener(onAnalytics);
    DebugTraceStore.instance.revision.addListener(onTrace);
    DebugLensServices.listenable.addListener(onRegistry);
    addTearDown(() {
      DebugCrashStore.instance.revision.removeListener(onCrash);
      DebugAnalyticsStore.instance.revision.removeListener(onAnalytics);
      DebugTraceStore.instance.revision.removeListener(onTrace);
      DebugLensServices.listenable.removeListener(onRegistry);
    });

    // Each of these is reachable from inside a build in a real app: a crash
    // reported by FlutterError.onError, an analytics event logged from a
    // widget, a trace stopped in a builder.
    DebugLens.instance.recordCrash(
      DebugLensCrashEvent(error: 'boom', stackTrace: StackTrace.current),
    );
    DebugLens.instance.recordAnalyticsEvent('screen_view');
    DebugLens.instance.recordTrace('render', const Duration(milliseconds: 5));
    DebugLens.recordNotification(title: 'hello');
    DebugLens.recordDeeplink('app://x');

    expect(
      [crash, analytics, trace, registry],
      [0, 0, 0, 0],
      reason: 'signalling inline reaches markNeedsBuild during a build',
    );

    await Future<void>.delayed(Duration.zero);
    expect(crash, 1);
    expect(analytics, 1);
    expect(trace, 1);
    expect(registry, greaterThanOrEqualTo(1));
  });

  testWidgets('logging during a build does not trip markNeedsBuild', (
    tester,
  ) async {
    // The real loop: DebugLens.wrap provides the logger, a widget logs while
    // building, the notification marks a dependent dirty mid-build, the
    // framework asserts, and the host routes that error back into DebugLens.
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            DebugLens.wrap(child ?? const SizedBox.shrink()),
        home: Builder(
          builder: (context) {
            DebugLensLogger().d('logged from inside build');
            DebugStore.instance.recordNavigation(
              action: NavAction.push,
              routeName: '/from-build',
            );
            DebugStore.instance.recordBlocEvent(
              kind: BlocActionKind.change,
              blocName: 'FromBuildBloc',
            );
            DebugLens.instance.recordCrash(
              DebugLensCrashEvent(error: 'from build'),
            );
            DebugLens.instance.recordAnalyticsEvent('from_build');
            DebugLens.instance.recordTrace('t', const Duration(seconds: 1));
            DebugLens.recordNotification(title: 'from build');
            DebugLens.recordDeeplink('app://from-build');
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
