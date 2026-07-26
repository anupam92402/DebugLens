import 'package:flutter/material.dart';

import '../../data/debug_service_source.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Services aggregator. Shows a vertical list of the registered services
/// (Remote Config, Crashlytics, Performance, Analytics, …); tapping one opens
/// its own screen. Services come from the host-registered
/// [DebugLensServices.services]; DebugLens keeps no copy.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(DebugStrings.servicesTitle)),
      // Listen to the registry so services registered after this screen is
      // built (e.g. during async startup) appear without a manual refresh.
      body: ValueListenableBuilder<List<DebugLensService>>(
        valueListenable: DebugLensServices.listenable,
        builder: (context, services, _) {
          if (services.isEmpty) {
            return const EmptyState(
              icon: Icons.cloud_outlined,
              message: DebugStrings.servicesEmpty,
            );
          }
          return ListView.separated(
            itemCount: services.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: DebugColors.border),
            itemBuilder: (_, i) {
              final service = services[i];
              return ListTile(
                leading: const Icon(Icons.cloud_outlined, size: 20),
                title: Text(service.name, style: monoStyle(size: 13)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(DebugRoutes.serviceDetail, arguments: service),
              );
            },
          );
        },
      ),
    );
  }
}
