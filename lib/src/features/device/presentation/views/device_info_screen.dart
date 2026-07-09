import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';

class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = context.watch<DebugStore>().deviceInfo;
    return Scaffold(
      appBar: AppBar(title: const Text(DebugStrings.deviceTitle)),
      body: ListView(
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
      ),
    );
  }
}
