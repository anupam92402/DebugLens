import 'package:flutter/material.dart';

import '../../theme/debug_theme.dart';
import '../debug_widgets.dart';

/// SectionCard for the request's query parameters. Always rendered (even
/// when empty, where it shows "none") so the Overview tab's section layout
/// stays predictable across rows.
class NetworkQueryCard extends StatelessWidget {
  final Map<String, dynamic> queryParameters;
  final void Function(String text, String label) onCopy;

  const NetworkQueryCard({
    super.key,
    required this.queryParameters,
    required this.onCopy,
  });

  /// `key: value\n…` representation — used by the COPY button.
  String _asBlock() {
    if (queryParameters.isEmpty) return 'none';
    return queryParameters.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Query parameters',
      onCopy: queryParameters.isEmpty
          ? null
          : () => onCopy(_asBlock(), 'Query parameters'),
      child: queryParameters.isEmpty
          ? Text('none',
              style: monoStyle(size: 12, color: DebugPalette.textMuted))
          : Column(
              children: [
                for (final e in queryParameters.entries)
                  KvRow(label: e.key, value: e.value.toString()),
              ],
            ),
    );
  }
}
