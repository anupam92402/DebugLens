// Smoke test for the example app shell.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:debug_lens_example/src/app.dart';
import 'package:debug_lens_example/src/core/di/service_locator.dart';

void main() {
  testWidgets('Shell renders tabs, FAB and AppBar actions', (tester) async {
    // DebugLens.wrap() installs a global debugPrint override (console capture).
    // The test framework asserts foundation debug vars are unchanged by the end
    // of the test body, so remember the framework's debugPrint and restore it.
    final originalDebugPrint = debugPrint;

    // The API playground tab (built eagerly by the IndexedStack) resolves its
    // bloc from get_it, so the locator must be set up first.
    setupLocator();

    await tester.pumpWidget(const ExampleApp());
    // Let the dummy repositories finish their simulated fetch delays.
    await tester.pump(const Duration(milliseconds: 500));

    // Bottom nav options (2 tabs + docked FAB = 3 options).
    expect(find.text('APIs'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // AppBar actions.
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // Home tab dummy data is visible.
    expect(find.text('Recent activity'), findsOneWidget);

    // Nested navigation + data passing: tapping an activity pushes its detail
    // screen on the tab's nested navigator (bottom bar/FAB stay visible) and
    // the passed id resolves to the full activity from HomeBloc.
    await tester.tap(find.text('Review sprint board'));
    await tester.pumpAndSettle();
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Mark as done'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    debugPrint = originalDebugPrint;
  });
}
