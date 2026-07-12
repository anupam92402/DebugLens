import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Headers SectionCard. [renderAsBlock] true → one copyable `key: value`
/// block; false → a `KvRow` per header (with authorization tap-to-reveal).
class NetworkHeadersCard extends StatelessWidget {
  final String title;
  final Map<String, String> headers;
  final bool renderAsBlock;

  /// Copy handler; when null no copy button is shown (e.g. response headers,
  /// which are display-only — not copied or shared anywhere).
  final void Function(String text, String label)? onCopy;

  const NetworkHeadersCard({
    super.key,
    required this.title,
    required this.headers,
    this.onCopy,
    this.renderAsBlock = false,
  });

  /// Multi-line `key: value` block, or `DebugStrings.networkNone` when empty.
  String _asBlock() {
    if (headers.isEmpty) return DebugStrings.networkNone;
    return headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final copy = onCopy;
    return SectionCard(
      title: title,
      onCopy: (copy == null || headers.isEmpty)
          ? null
          : () => copy(_asBlock(), title),
      child: _content(),
    );
  }

  Widget _content() {
    if (renderAsBlock) {
      return SelectableText(
        _asBlock(),
        style: monoStyle(
          size: 12,
          color: headers.isEmpty ? DebugColors.textMuted : null,
        ),
      );
    }
    if (headers.isEmpty) {
      return Text(
        DebugStrings.networkNone,
        style: monoStyle(size: 12, color: DebugColors.textMuted),
      );
    }
    return Column(
      children: [
        for (final e in headers.entries)
          KvRow(
            label: e.key,
            value: e.value,
            // Mask the Authorization header by default — common bug-report
            // antipattern is leaking the bearer token in a screenshot.
            sensitive: e.key.toLowerCase() == 'authorization',
          ),
      ],
    );
  }
}
