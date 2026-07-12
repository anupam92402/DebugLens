import 'package:flutter/material.dart';

import '../../domain/pref_entry.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'pref_detail_dialog.dart';
import '../../../../shared/theme/debug_colors.dart';

/// One SharedPreferences row — key (with a `*` for encrypted entries), type
/// chip, value, a copy+share action, and tap-to-open detail dialog. Encrypted
/// values are masked unless [revealEncrypted].
class PrefTile extends StatelessWidget {
  final DebugLensPrefEntry entry;
  final bool revealEncrypted;
  final Future<void> Function(String text, String label) onCopyShare;

  const PrefTile({
    super.key,
    required this.entry,
    required this.onCopyShare,
    this.revealEncrypted = false,
  });

  bool get _masked => entry.encrypted && !revealEncrypted;

  void _openDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => PrefDetailDialog(entry: entry, onCopyShare: onCopyShare),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                  color: scheme.primary,
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (entry.type != DebugLensPrefType.unknown)
            StatusChip(entry.type.label, color: toneForPrefType(entry.type)),
        ],
      ),
      subtitle: Text(
        _masked ? DebugConstants.maskedValue : entry.value,
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
