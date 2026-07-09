import 'package:flutter/material.dart';

import '../../data/debug_firebase_source.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Firebase aggregator. Shows a vertical list of the registered Firebase
/// services (Remote Config, Crashlytics, Performance, Analytics, …); tapping
/// one opens its own screen. Services come from the host-registered
/// [DebugLensFirebase.services]; DebugLens keeps no copy.
class FirebaseScreen extends StatelessWidget {
  const FirebaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(DebugStrings.firebaseTitle)),
      // Listen to the registry so services registered after this screen is
      // built (e.g. during async startup) appear without a manual refresh.
      body: ValueListenableBuilder<List<DebugLensFirebaseService>>(
        valueListenable: DebugLensFirebase.listenable,
        builder: (context, services, __) {
          if (services.isEmpty) {
            return const EmptyState(
              icon: Icons.local_fire_department,
              message: DebugStrings.firebaseEmpty,
            );
          }
          return ListView.separated(
            itemCount: services.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: DebugPalette.border),
            itemBuilder: (_, i) {
              final service = services[i];
              return ListTile(
                leading: const Icon(Icons.local_fire_department, size: 20),
                title: Text(service.name, style: monoStyle(size: 13)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(DebugRoutes.firebaseService, arguments: service),
              );
            },
          );
        },
      ),
    );
  }
}
