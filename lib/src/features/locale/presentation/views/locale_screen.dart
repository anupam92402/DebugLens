import 'package:flutter/material.dart';

import '../../data/debug_locale_source.dart';
import '../../data/locale_log_share.dart';
import '../../domain/locale_data.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../widgets/locale_category_section.dart';
import 'active_locale_label.dart';

/// Localized-strings inspector. Reads the app's live locale strings from the
/// host-registered [DebugLensLocale.source] each build (no copy kept), grouped
/// into collapsible category dropdowns and paginated a batch of categories at
/// a time so a large locale stays responsive. Owns the search query, expanded
/// set, sort order, and current page.
class LocaleScreen extends StatefulWidget {
  const LocaleScreen({super.key});

  @override
  State<LocaleScreen> createState() => _LocaleScreenState();
}

class _LocaleScreenState extends State<LocaleScreen>
    with WidgetsBindingObserver {
  /// Categories rendered per page — a fixed batch; the page count is derived
  /// from the filtered category total. Paging whole sections (not rows) keeps
  /// collapse behaviour and the per-category counts honest.
  static const int _categoriesPerPage = 15;

  final ValueNotifier<String> _query = ValueNotifier<String>('');
  final ValueNotifier<bool> _sortAsc = ValueNotifier<bool>(true);
  final ValueNotifier<int> _page = ValueNotifier<int>(0);
  final ValueNotifier<Set<String>> _expanded = ValueNotifier<Set<String>>(
    const {},
  );

  // Bumped on app resume to re-pull the (pull-based) locale snapshot.
  final ValueNotifier<int> _refreshTick = ValueNotifier<int>(0);

  // Memo: filtering/grouping/sorting is recomputed only when the query, sort,
  // or refresh changes — not on every page turn or expand toggle.
  String? _memoKey;
  List<MapEntry<String, List<MapEntry<String, String>>>> _memoGroups = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _query.dispose();
    _sortAsc.dispose();
    _page.dispose();
    _expanded.dispose();
    _refreshTick.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshTick.value++;
  }

  void _toggle(String category) {
    final next = {..._expanded.value};
    if (!next.add(category)) next.remove(category);
    _expanded.value = next;
  }

  Future<void> _share() {
    final locale = DebugLensLocale.source?.call() ?? DebugLensLocaleData.empty;
    // Share the current filtered/sorted view, not the whole locale.
    final groups = _filteredGroups(locale);
    final entries = <String, dynamic>{
      for (final g in groups) g.key: {for (final e in g.value) e.key: e.value},
    };
    final view = DebugLensLocaleData(entries: entries, label: locale.label);
    final box = context.findRenderObject() as RenderBox?;
    return LocaleLogShare.share(
      view,
      origin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  /// Cached view of [_filteredGroups] — recomputed only when the memo key
  /// (query + sort + refresh) changes.
  List<MapEntry<String, List<MapEntry<String, String>>>> _groups(
    DebugLensLocaleData locale,
  ) {
    final key = '${_query.value}|${_sortAsc.value}|${_refreshTick.value}';
    if (key != _memoKey) {
      _memoKey = key;
      _memoGroups = _filteredGroups(locale);
    }
    return _memoGroups;
  }

  /// Groups the locale by category, orders categories (per [_sortAsc]) and
  /// their rows, and applies the search filter. Categories left with no
  /// matching rows are dropped.
  List<MapEntry<String, List<MapEntry<String, String>>>> _filteredGroups(
    DebugLensLocaleData locale,
  ) {
    final grouped = locale.group();
    final q = _query.value.toLowerCase();
    final categories = grouped.keys.toList()..sort();
    if (!_sortAsc.value) {
      final reversed = categories.reversed.toList();
      categories
        ..clear()
        ..addAll(reversed);
    }
    final result = <MapEntry<String, List<MapEntry<String, String>>>>[];
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
      if (matched.isNotEmpty) result.add(MapEntry(category, matched));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(DebugStrings.localeTitle),
        actions: [
          IconButton(
            tooltip: DebugStrings.localeShareTooltip,
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
          ValueListenableBuilder<int>(
            valueListenable: _refreshTick,
            builder: (_, _, _) {
              final label =
                  DebugLensLocale.source?.call().label ??
                  DebugLensLocaleData.empty.label;
              return label.isEmpty
                  ? const SizedBox.shrink()
                  : ActiveLocaleLabel(label: label);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: DebugSearchField(
                    hint: DebugStrings.localeSearchHint,
                    onChanged: (v) {
                      _query.value = v;
                      _page.value = 0;
                    },
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _sortAsc,
                  builder: (_, asc, _) => SortToggle(
                    newestFirst: asc,
                    onToggle: () {
                      _sortAsc.value = !asc;
                      _page.value = 0;
                    },
                    newestTooltip: DebugStrings.localeSortAsc,
                    oldestTooltip: DebugStrings.localeSortDesc,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                _query,
                _sortAsc,
                _page,
                _expanded,
                _refreshTick,
              ]),
              builder: (context, _) {
                // Pulled live each build — DebugLens keeps no copy.
                final locale =
                    DebugLensLocale.source?.call() ?? DebugLensLocaleData.empty;
                final groups = _groups(locale);
                if (groups.isEmpty) {
                  return EmptyState(
                    icon: Icons.translate,
                    message: locale.entries.isEmpty
                        ? DebugStrings.localeEmpty
                        : DebugStrings.localeNoMatches,
                  );
                }

                final pageCount = (groups.length / _categoriesPerPage).ceil();
                final page = _page.value.clamp(0, pageCount - 1);
                final start = page * _categoriesPerPage;
                final end = (start + _categoriesPerPage).clamp(
                  0,
                  groups.length,
                );
                final window = groups.sublist(start, end);
                final searching = _query.value.isNotEmpty;

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: window.length,
                        itemBuilder: (_, i) {
                          final group = window[i];
                          return LocaleCategorySection(
                            category: group.key,
                            entries: group.value,
                            expanded:
                                searching ||
                                _expanded.value.contains(group.key),
                            onToggle: () => _toggle(group.key),
                          );
                        },
                      ),
                    ),
                    if (pageCount > 1) _pager(page, pageCount),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pager(int page, int pageCount) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DebugColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: DebugStrings.localePrevPage,
              icon: const Icon(Icons.chevron_left),
              onPressed: page == 0 ? null : () => _page.value = page - 1,
            ),
            Text(
              DebugStrings.localePageLabel(page + 1, pageCount),
              style: monoStyle(size: 12, color: DebugColors.textMuted),
            ),
            IconButton(
              tooltip: DebugStrings.localeNextPage,
              icon: const Icon(Icons.chevron_right),
              onPressed: page >= pageCount - 1
                  ? null
                  : () => _page.value = page + 1,
            ),
          ],
        ),
      ),
    );
  }
}
