import 'package:flutter/material.dart';

import '../../domain/deeplink_entry.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'deeplink_tile.dart';

/// Captured deep-link feed. Each row breaks the URI into its components
/// (scheme / host / path) and renders query parameters as JSON.
class DeeplinksTab extends StatelessWidget {
  final List<DeeplinkEntry> items;

  const DeeplinksTab({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.link_off,
        message: DebugStrings.deeplinksEmpty,
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: DebugPalette.border),
      itemBuilder: (_, i) => DeeplinkTile(entry: items[i]),
    );
  }
}
