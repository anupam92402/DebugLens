import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// One key/value row in the Locale screen. Layout uses Expanded(flex:2) for
/// the key and Expanded(flex:3) for the value so the column-header in the
/// screen lines up cleanly above the rows. Two tiny copy icons live to the
/// right of each text — one tap copies the corresponding side.
class LocaleRow extends StatelessWidget {
  final MapEntry<String, String> entry;

  const LocaleRow({super.key, required this.entry});

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    DebugToast.show(
      context,
      DebugStrings.commonCopied(label),
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SelectableText(
              entry.key,
              style: monoStyle(size: 12, color: DebugColors.textMuted),
            ),
          ),
          CopyIcon(
            padding: const EdgeInsets.only(left: 4, right: 8, top: 1),
            size: 13,
            onTap: () => _copy(context, entry.key, DebugStrings.localeKey),
          ),
          Expanded(
            flex: 3,
            child: SelectableText(entry.value, style: monoStyle(size: 13)),
          ),
          CopyIcon(
            padding: const EdgeInsets.only(left: 4, top: 1),
            size: 13,
            onTap: () => _copy(context, entry.value, DebugStrings.localeValue),
          ),
        ],
      ),
    );
  }
}
