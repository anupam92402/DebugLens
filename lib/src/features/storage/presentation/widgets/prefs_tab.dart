import 'package:flutter/material.dart';

import '../../domain/pref_entry.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'pref_tile.dart';
import '../../../../shared/theme/debug_colors.dart';

/// SharedPreferences feed. Filters by key or value, marks encrypted entries
/// with a `*` (values hidden by default, revealed by the eye toggle),
/// copies/shares per row, and opens a detail dialog on tap.
class PrefsTab extends StatefulWidget {
  final List<DebugLensPrefEntry> entries;
  final String query;
  final ValueChanged<String> onSearch;

  /// Clipboard + system share, wired from the screen. `(text, label)`.
  final Future<void> Function(String text, String label) onCopyShare;

  const PrefsTab({
    super.key,
    required this.entries,
    required this.query,
    required this.onSearch,
    required this.onCopyShare,
  });

  @override
  State<PrefsTab> createState() => _PrefsTabState();
}

class _PrefsTabState extends State<PrefsTab> {
  // Encrypted values are hidden by default; the eye toggle reveals them.
  final ValueNotifier<bool> _revealEncrypted = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _revealEncrypted.dispose();
    super.dispose();
  }

  List<DebugLensPrefEntry> get _filtered {
    if (widget.query.isEmpty) return widget.entries;
    final q = widget.query.toLowerCase();
    return widget.entries
        .where(
          (e) =>
              e.key.toLowerCase().contains(q) ||
              e.value.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final hasEncrypted = widget.entries.any((e) => e.encrypted);
    return Column(
      children: [
        if (hasEncrypted) _encryptedNote(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: DebugSearchField(
            hint: DebugStrings.storageSearchKeys,
            onChanged: widget.onSearch,
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: Icons.sd_storage,
                  message: widget.entries.isEmpty
                      ? DebugStrings.storageNoPreferences
                      : DebugStrings.storageNoMatchingKeys,
                )
              : ValueListenableBuilder<bool>(
                  valueListenable: _revealEncrypted,
                  builder: (_, reveal, _) => ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: DebugColors.border),
                    itemBuilder: (_, i) => PrefTile(
                      entry: filtered[i],
                      revealEncrypted: reveal,
                      onCopyShare: widget.onCopyShare,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// "`*` marks an encrypted key" note + eye toggle to reveal masked values.
  Widget _encryptedNote(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          Text(
            DebugConstants.encryptedMarker,
            style: monoStyle(
              size: 12,
              weight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              DebugStrings.storageEncryptedNote,
              style: monoStyle(size: 11, color: DebugColors.textMuted),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _revealEncrypted,
            builder: (_, reveal, _) => IconButton(
              tooltip: reveal
                  ? DebugStrings.storageHideEncrypted
                  : DebugStrings.storageShowEncrypted,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                reveal ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: DebugColors.textMuted,
              ),
              onPressed: () => _revealEncrypted.value = !reveal,
            ),
          ),
        ],
      ),
    );
  }
}
