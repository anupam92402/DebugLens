import 'package:flutter/material.dart';

import '../../theme/debug_theme.dart';
import '../debug_widgets.dart';

/// SectionCard for either the inline headers summary (Overview tab) or the
/// structured per-row Request/Response headers cards below it.
///
/// One widget covers both shapes by switching between:
///   - [renderAsBlock] = true  → multi-line stringified `key: value\n…`
///     block, mainly for the Overview inline "Headers" card where the goal
///     is to copy the whole block in one tap.
///   - [renderAsBlock] = false → structured `KvRow` per header, with
///     authorization tap-to-reveal. Used by the Request/Response headers
///     cards below the inline block.
class NetworkHeadersCard extends StatelessWidget {
  final String title;
  final Map<String, String> headers;
  final bool renderAsBlock;
  final void Function(String text, String label) onCopy;

  const NetworkHeadersCard({
    super.key,
    required this.title,
    required this.headers,
    required this.onCopy,
    this.renderAsBlock = false,
  });

  /// Multi-line `key: value\n…` representation. `'none'` when empty so the
  /// inline block in Overview reads sensibly when the request has no
  /// headers (e.g. an OPTIONS preflight).
  String _asBlock() {
    if (headers.isEmpty) return 'none';
    return headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      onCopy: headers.isEmpty ? null : () => onCopy(_asBlock(), title),
      child: _content(),
    );
  }

  Widget _content() {
    if (renderAsBlock) {
      return SelectableText(
        _asBlock(),
        style: monoStyle(
          size: 12,
          color: headers.isEmpty ? DebugPalette.textMuted : null,
        ),
      );
    }
    if (headers.isEmpty) {
      return Text('none',
          style: monoStyle(size: 12, color: DebugPalette.textMuted));
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
