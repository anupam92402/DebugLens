import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

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
    if (queryParameters.isEmpty) return DebugStrings.networkNone;
    return queryParameters.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: DebugStrings.networkQueryParams,
      onCopy: queryParameters.isEmpty
          ? null
          : () => onCopy(_asBlock(), DebugStrings.networkQueryParams),
      child: queryParameters.isEmpty
          ? Text(
              DebugStrings.networkNone,
              style: monoStyle(size: 12, color: DebugColors.textMuted),
            )
          : Column(
              children: [
                for (final e in queryParameters.entries)
                  KvRow(label: e.key, value: e.value.toString()),
              ],
            ),
    );
  }
}
