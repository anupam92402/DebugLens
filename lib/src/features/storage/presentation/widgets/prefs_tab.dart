import 'package:flutter/material.dart';

import '../../domain/pref_entry.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'pref_tile.dart';

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
            hint: DebugStrings.storageSearchKeys,
            onChanged: onSearch,
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: Icons.sd_storage,
                  message: entries.isEmpty
                      ? DebugStrings.storageNoPreferences
                      : DebugStrings.storageNoMatchingKeys,
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: DebugPalette.border),
                  itemBuilder: (_, i) =>
                      PrefTile(entry: filtered[i], onCopyShare: onCopyShare),
                ),
        ),
      ],
    );
  }
}
