import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// A saved note — the example's demo table.
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get tag => text().withDefault(const Constant('general'))();
  DateTimeColumn get createdAt => dateTime()();
}

/// The example app's real Drift/SQLite database. DebugLens reads it only
/// through [DriftDebugLensDatabase]; the app itself owns this class.
@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'example_app'));

  @override
  int get schemaVersion => 1;

  /// Inserts a few demo notes the first time the DB is created.
  Future<void> seedIfEmpty() async {
    final count = await select(notes).get();
    if (count.isNotEmpty) return;
    await batch((b) {
      b.insertAll(notes, [
        NotesCompanion.insert(
          title: 'Welcome',
          body: 'Your first note in the example app.',
          tag: const Value('intro'),
          createdAt: DateTime.now(),
        ),
        NotesCompanion.insert(
          title: 'Groceries',
          body: 'Milk, eggs, coffee.',
          tag: const Value('personal'),
          createdAt: DateTime.now(),
        ),
        NotesCompanion.insert(
          title: 'Ship DebugLens storage',
          body: 'Wire drift + shared_preferences into the inspector.',
          tag: const Value('work'),
          createdAt: DateTime.now(),
        ),
      ]);
    });
  }
}
