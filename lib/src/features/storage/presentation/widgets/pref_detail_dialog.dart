import 'package:flutter/material.dart';

import '../../domain/pref_entry.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Detail dialog using the Network screen's glass [SectionCard] containers:
/// one for the key, one for the value, each with its own COPY (copy + share),
/// plus a combined "copy key + value" action.
class PrefDetailDialog extends StatelessWidget {
  final DebugLensPrefEntry entry;
  final Future<void> Function(String text, String label) onCopyShare;

  const PrefDetailDialog({
    super.key,
    required this.entry,
    required this.onCopyShare,
  });

  /// Combined "key + value" payload shared by the copy actions.
  static String pair(DebugLensPrefEntry e) => '${e.key}: ${e.value}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DebugColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DebugStrings.storagePreference,
                      style: monoStyle(size: 14),
                    ),
                  ),
                  if (entry.encrypted)
                    StatusChip(
                      DebugStrings.storageEncrypted,
                      color: DebugColors.info,
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionCard(
                      title: DebugStrings.storageKeyTitle,
                      onCopy: () =>
                          onCopyShare(entry.key, DebugStrings.storageKeyTitle),
                      child: SelectableText(
                        entry.key,
                        style: monoStyle(size: 13),
                      ),
                    ),
                    SectionCard(
                      title: DebugStrings.storageValueTitle,
                      onCopy: () => onCopyShare(
                        entry.value,
                        DebugStrings.storageValueTitle,
                      ),
                      child: SelectableText(
                        entry.value,
                        style: monoStyle(size: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => onCopyShare(
                      pair(entry),
                      DebugStrings.storagePreference,
                    ),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text(DebugStrings.commonCopy),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(DebugStrings.commonClose),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
