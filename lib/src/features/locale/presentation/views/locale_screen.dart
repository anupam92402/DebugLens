import 'package:flutter/material.dart';

import '../../data/debug_locale_source.dart';
import '../../domain/locale_data.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../widgets/locale_category_section.dart';
import 'active_locale_label.dart';

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
    DebugLensLocaleData locale,
  ) {
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
                .where(
                  (e) =>
                      e.key.toLowerCase().contains(q) ||
                      e.value.toLowerCase().contains(q),
                )
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
        title: const Text(DebugStrings.localeTitle),
        actions: [
          if (locale.label.isNotEmpty) ActiveLocaleLabel(label: locale.label),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: DebugSearchField(
              hint: DebugStrings.localeSearchHint,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: groups.isEmpty
                ? EmptyState(
                    icon: Icons.translate,
                    message: locale.entries.isEmpty
                        ? DebugStrings.localeEmpty
                        : DebugStrings.localeNoMatches,
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
