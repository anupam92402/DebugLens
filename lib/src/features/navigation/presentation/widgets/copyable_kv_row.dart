import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'copy_icon.dart';

/// KV row with a trailing copy icon — used for the from/to labels so each
/// route name is one tap to clipboard.
class CopyableKvRow extends StatelessWidget {
  final String label;
  final String value;
  final void Function(BuildContext, String, String) onCopy;

  const CopyableKvRow({
    super.key,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: KvRow(label: label, value: value),
        ),
        CopyIcon(
          tooltip: DebugStrings.commonCopyField(label),
          onTap: () =>
              onCopy(context, value, DebugStrings.commonFieldCopied(label)),
        ),
      ],
    );
  }
}
