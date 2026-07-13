import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/sequence_badge.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Expandable row for one Firebase key/value fact, styled like the Navigation
/// event rows: a position badge, the group as a colored chip and the key in
/// mono, a one-line value preview, expanding to the full (copyable) value.
class FirebaseEntryTile extends StatelessWidget {
  final int number;
  final String group;
  final Color color;
  final String label;
  final String value;
  final bool sensitive;

  const FirebaseEntryTile({
    super.key,
    required this.number,
    required this.group,
    required this.color,
    required this.label,
    required this.value,
    this.sensitive = false,
  });

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    DebugToast.show(context, DebugStrings.commonFieldCopied(label));
  }

  @override
  Widget build(BuildContext context) {
    // Sensitive values stay masked in the preview; expanding reveals them.
    final preview = sensitive ? '•' * 12 : value;
    return ExpansionTile(
      leading: SequenceBadge('#$number'),
      title: Row(
        children: [
          StatusChip(group, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(size: 13),
            ),
          ),
        ],
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: monoStyle(size: 11, color: DebugColors.textMuted),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: SelectableText(value, style: monoStyle(size: 12))),
            CopyIcon(
              tooltip: DebugStrings.commonCopyField(label),
              onTap: () => _copy(context),
            ),
          ],
        ),
      ],
    );
  }
}
