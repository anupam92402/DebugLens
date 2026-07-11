import 'package:flutter/material.dart';

import 'copy_icon.dart';
import 'text_styles.dart';
import '../debug_strings.dart';
import '../theme/debug_colors.dart';

/// Label/value row. When [sensitive] is true the value is masked with a
/// tap-to-reveal toggle. When [onCopy] is provided a trailing copy icon
/// copies the value (called as `onCopy(context, value, message)`).
class KvRow extends StatefulWidget {
  final String label;
  final String value;
  final bool sensitive;
  final void Function(BuildContext, String, String)? onCopy;

  const KvRow({
    super.key,
    required this.label,
    required this.value,
    this.sensitive = false,
    this.onCopy,
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
              style: monoStyle(size: 12, color: DebugColors.textMuted),
            ),
          ),
          Expanded(
            child: SelectableText(
              masked ? '•' * 12 : widget.value,
              style: monoStyle(size: 12),
            ),
          ),
          if (widget.onCopy != null)
            CopyIcon(
              tooltip: DebugStrings.commonCopyField(widget.label),
              onTap: () => widget.onCopy!(
                context,
                widget.value,
                DebugStrings.commonFieldCopied(widget.label),
              ),
            ),
          if (widget.sensitive)
            GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
              child: Icon(
                _revealed ? Icons.visibility_off : Icons.visibility,
                size: 16,
                color: DebugColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
