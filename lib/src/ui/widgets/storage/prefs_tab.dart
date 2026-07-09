import 'package:flutter/material.dart';

import '../../../core/debug_shared_prefs_source.dart';
import '../../theme/debug_theme.dart';
import '../debug_widgets.dart';

/// SharedPreferences feed. Filters by key, marks encrypted entries with a `*`,
/// lets each row copy+share its key and value, and opens a detail dialog (built
/// from the same glass [SectionCard] containers as the Network screen) on tap.
class PrefsTab extends StatelessWidget {
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

  /// Combined "key + value" payload shared by the copy actions.
  static String _pair(DebugLensPrefEntry e) => '${e.key}: ${e.value}';

  List<DebugLensPrefEntry> get _filtered {
    if (query.isEmpty) return entries;
    final q = query.toLowerCase();
    return entries.where((e) => e.key.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: DebugSearchField(
            hint: 'Search keys',
            onChanged: onSearch,
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: Icons.sd_storage,
                  message:
                      entries.isEmpty ? 'No preferences' : 'No matching keys',
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: DebugPalette.border),
                  itemBuilder: (_, i) => _PrefTile(
                    entry: filtered[i],
                    onCopyShare: onCopyShare,
                  ),
                ),
        ),
      ],
    );
  }
}

class _PrefTile extends StatelessWidget {
  final DebugLensPrefEntry entry;
  final Future<void> Function(String text, String label) onCopyShare;

  const _PrefTile({required this.entry, required this.onCopyShare});

  void _openDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) =>
          _PrefDetailDialog(entry: entry, onCopyShare: onCopyShare),
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
                '*',
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
        style: monoStyle(size: 12, color: DebugPalette.textMuted),
      ),
      trailing: IconButton(
        tooltip: 'Copy',
        icon: const Icon(Icons.copy, size: 18, color: DebugPalette.textMuted),
        onPressed: () => onCopyShare(PrefsTab._pair(entry), 'Preference'),
      ),
      onTap: () => _openDetail(context),
    );
  }
}

/// Detail dialog using the Network screen's glass [SectionCard] containers:
/// one for the key, one for the value, each with its own COPY (copy + share),
/// plus a combined "copy key + value" action.
class _PrefDetailDialog extends StatelessWidget {
  final DebugLensPrefEntry entry;
  final Future<void> Function(String text, String label) onCopyShare;

  const _PrefDetailDialog({required this.entry, required this.onCopyShare});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DebugPalette.surface,
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
                    child: Text('Preference', style: monoStyle(size: 14)),
                  ),
                  if (entry.encrypted)
                    StatusChip('ENCRYPTED', color: DebugPalette.info),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionCard(
                      title: 'Key',
                      onCopy: () => onCopyShare(entry.key, 'Key'),
                      child: SelectableText(
                        entry.key,
                        style: monoStyle(size: 13),
                      ),
                    ),
                    SectionCard(
                      title: 'Value',
                      onCopy: () => onCopyShare(entry.value, 'Value'),
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
                    onPressed: () =>
                        onCopyShare(PrefsTab._pair(entry), 'Preference'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
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
