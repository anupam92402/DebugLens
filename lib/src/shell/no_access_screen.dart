import 'package:flutter/material.dart';

import '../shared/debug_strings.dart';
import '../shared/widgets/empty_state.dart';
import 'debug_app_bar.dart';

/// Shown in place of a tab when the current role may open none.
class NoAccessScreen extends StatelessWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: DebugAppBar(title: Text(DebugStrings.dashboardTitle)),
      body: EmptyState(
        icon: Icons.lock_outline,
        message: DebugStrings.dashboardNoAccess,
      ),
    );
  }
}
