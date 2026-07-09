import 'package:flutter/material.dart';

import '../theme/debug_theme.dart';
import 'text_styles.dart';

/// Label/value row. When [sensitive] is true the value is masked with a
/// tap-to-reveal toggle.
class KvRow extends StatefulWidget {
  final String label;
  final String value;
  final bool sensitive;

  const KvRow({
    super.key,
    required this.label,
    required this.value,
    this.sensitive = false,
  });

  @override
  State<KvRow> createState() => _KvRowState();
}

class _KvRowState extends State<KvRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final masked = widget.sensitive && !_revealed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              widget.label,
              style: monoStyle(size: 12, color: DebugPalette.textMuted),
            ),
          ),
          Expanded(
            child: SelectableText(
              masked ? '•' * 12 : widget.value,
              style: monoStyle(size: 12),
            ),
          ),
          if (widget.sensitive)
            GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
              child: Icon(
                _revealed ? Icons.visibility_off : Icons.visibility,
                size: 16,
                color: DebugPalette.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
