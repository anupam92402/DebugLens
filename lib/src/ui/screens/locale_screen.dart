import 'package:flutter/material.dart';

import '../../core/debug_locale_source.dart';
import '../theme/debug_theme.dart';
import '../widgets/debug_widgets.dart';
import '../widgets/locale/locale_category_section.dart';

/// Localized-strings inspector. Reads the app's live locale strings from the
/// host-registered [DebugLensLocale.source] on each build and renders them
/// grouped by category into collapsible dropdowns (e.g. `ACTION`, `PAYMENT`),
/// each expanding to its `key → value` rows — DebugLens stores no copy of the
/// data. Owns the search query and which sections are expanded.
class LocaleScreen extends StatefulWidget {
  const LocaleScreen({super.key});

  @override
  State<LocaleScreen> createState() => _LocaleScreenState();
}

class _LocaleScreenState extends State<LocaleScreen> {
  String _query = '';

  /// Categories the user has manually expanded (only consulted when no search
  /// is active — a live search auto-expands every matching section instead).
  final Set<String> _expanded = <String>{};

  void _toggle(String category) => setState(() {
        _expanded.contains(category)
            ? _expanded.remove(category)
            : _expanded.add(category);
      });

  /// Groups the locale map by category, sorts categories and their rows, then
  /// applies the search filter. A category whose own name matches keeps all its
  /// rows; otherwise only rows matching key or value are kept. Categories left
  /// with no rows are dropped. Pure — easy to reason about and test.
  List<MapEntry<String, List<MapEntry<String, String>>>> _filteredGroups(
      DebugLensLocaleData locale) {
    final grouped = locale.group();
    final q = _query.toLowerCase();
    final result = <MapEntry<String, List<MapEntry<String, String>>>>[];

    final categories = grouped.keys.toList()..sort();
    for (final category in categories) {
      final rows = grouped[category]!.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final catMatches = category.toLowerCase().contains(q);
      final matched = (q.isEmpty || catMatches)
          ? rows
          : rows
              .where((e) =>
                  e.key.toLowerCase().contains(q) ||
                  e.value.toLowerCase().contains(q))
              .toList();
      if (matched.isNotEmpty) {
        result.add(MapEntry(category, matched));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Pulled live each build — DebugLens keeps no copy. Nested maps from the
    // app's we_lang source are grouped into category dropdowns for display.
    final locale = DebugLensLocale.source?.call() ?? DebugLensLocaleData.empty;
    final groups = _filteredGroups(locale);
    final searching = _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locale'),
        actions: [
          if (locale.label.isNotEmpty) _ActiveLocaleLabel(label: locale.label),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: DebugSearchField(
              hint: 'Search keys or values',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: groups.isEmpty
                ? EmptyState(
                    icon: Icons.translate,
                    message: locale.entries.isEmpty
                        ? 'No locale entries'
                        : 'No matches',
                  )
                : ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final group = groups[i];
                      return LocaleCategorySection(
                        category: group.key,
                        entries: group.value,
                        // A live search auto-expands every matching section so
                        // results are visible without extra taps.
                        expanded: searching || _expanded.contains(group.key),
                        onToggle: () => _toggle(group.key),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Compact AppBar action showing the currently-active locale label
/// (e.g. "English"). Pulled out so the icon + spacing logic is colocated.
class _ActiveLocaleLabel extends StatelessWidget {
  final String label;

  const _ActiveLocaleLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          const Icon(Icons.language, size: 14, color: DebugPalette.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: monoStyle(size: 12, color: DebugPalette.textMuted),
          ),
        ],
      ),
    );
  }
}
