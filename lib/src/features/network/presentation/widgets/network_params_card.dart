import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// SectionCard for a request's parameters, query or path (shows "none" when
/// empty).
class NetworkParamsCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> params;
  final void Function(String text, String label) onCopy;

  const NetworkParamsCard({
    super.key,
    required this.title,
    required this.params,
    required this.onCopy,
  });

  /// `key: value\n…` representation — used by the COPY button.
  String _asBlock() {
    if (params.isEmpty) return DebugStrings.networkNone;
    return params.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      onCopy: params.isEmpty ? null : () => onCopy(_asBlock(), title),
      child: params.isEmpty
          ? Text(
              DebugStrings.networkNone,
              style: monoStyle(size: 12, color: DebugColors.textMuted),
            )
          : Column(
              children: [
                for (final e in params.entries)
                  KvRow(label: e.key, value: e.value.toString()),
              ],
            ),
    );
  }
}
