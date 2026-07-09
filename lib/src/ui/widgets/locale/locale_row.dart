import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/debug_theme.dart';
import '../debug_toast.dart';
import '../debug_widgets.dart';

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
      '$label copied',
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
              style: monoStyle(size: 12, color: DebugPalette.textMuted),
            ),
          ),
          _CopyIcon(
            padding: const EdgeInsets.only(left: 4, right: 8, top: 1),
            onTap: () => _copy(context, entry.key, 'Key'),
          ),
          Expanded(
            flex: 3,
            child: SelectableText(entry.value, style: monoStyle(size: 13)),
          ),
          _CopyIcon(
            padding: const EdgeInsets.only(left: 4, top: 1),
            onTap: () => _copy(context, entry.value, 'Value'),
          ),
        ],
      ),
    );
  }
}

/// Compact tap-target wrapping a 13-px copy icon. Padding is passed in so
/// the leading vs trailing icon (different left/right margins) share the
/// same widget without an extra prop.
class _CopyIcon extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final VoidCallback onTap;

  const _CopyIcon({required this.padding, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: const Icon(
          Icons.content_copy,
          size: 13,
          color: DebugPalette.textMuted,
        ),
      ),
    );
  }
}
