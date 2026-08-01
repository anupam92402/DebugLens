import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/util/connectivity_label.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../data/device_info_source.dart';
import '../../domain/device_app_info.dart';

/// Read-only App / Device / Screen / Network facts.
class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  /// Held in the state, not created in `build` — a fresh future/stream per
  /// rebuild would resubscribe (and flash the spinner) on every frame.
  late final Future<List<InfoSection>> _platform = DeviceInfoSource.platform();
  late final Stream<ConnectivityResult> _connectivity = connectivityStream();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(DebugStrings.deviceTitle)),
      body: FutureBuilder<List<InfoSection>>(
        future: _platform,
        builder: (context, platform) {
          if (!platform.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<ConnectivityResult>(
            stream: _connectivity,
            builder: (context, connectivity) {
              final sections = [
                ...platform.data!,
                DeviceInfoSource.screen(context),
                DeviceInfoSource.network(connectivity.data),
              ];
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  for (final section in sections)
                    SectionCard(
                      title: section.title,
                      child: Column(
                        children: [
                          for (final e in section.values.entries)
                            KvRow(label: e.key, value: e.value),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
