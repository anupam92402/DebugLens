import '../domain/locale_data.dart';

/// Formats the active locale strings into the plain-text share section,
/// grouped by category. Pure — no UI.
class LocaleLogSerializer {
  LocaleLogSerializer._();

  static String dump(DebugLensLocaleData locale) {
    final grouped = locale.group();
    final categories = grouped.keys.toList()..sort();
    final count = locale.flatten().length;

    final b = StringBuffer()
      ..writeln(
        locale.label.isEmpty
            ? 'Locale ($count entries):'
            : 'Locale: ${locale.label} ($count entries)',
      );
    for (final category in categories) {
      b
        ..writeln()
        ..writeln('=== $category ===');
      final rows = grouped[category]!.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final e in rows) {
        b.writeln('${e.key}: ${e.value}');
      }
    }
    return b.toString().trimRight();
  }
}
