import 'package:flutter/material.dart';

import '../../domain/pref_entry.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'pref_detail_dialog.dart';
import '../../../../shared/theme/debug_colors.dart';

/// One SharedPreferences row — key (with a `*` for encrypted entries), value,
/// a copy+share action, and tap-to-open detail dialog.
class PrefTile extends StatelessWidget {
  final DebugLensPrefEntry entry;
  final Future<void> Function(String text, String label) onCopyShare;

  const PrefTile({super.key, required this.entry, required this.onCopyShare});

  void _openDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => PrefDetailDialog(entry: entry, onCopyShare: onCopyShare),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Flexible(child: Text(entry.key, style: monoStyle(size: 13))),
          // `*` marks keys stored through the encrypted preferences.
          if (entry.encrypted)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                DebugConstants.encryptedMarker,
                style: monoStyle(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        entry.value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: monoStyle(size: 12, color: DebugColors.textMuted),
      ),
      trailing: IconButton(
        tooltip: DebugStrings.commonCopy,
        icon: const Icon(Icons.copy, size: 18, color: DebugColors.textMuted),
        onPressed: () => onCopyShare(
          PrefDetailDialog.pair(entry),
          DebugStrings.storagePreference,
        ),
      ),
      onTap: () => _openDetail(context),
    );
  }
}
