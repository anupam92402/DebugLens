import 'package:flutter/material.dart';

import '../../data/debug_firebase_source.dart';
import '../../domain/info_group.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'error_state.dart';

/// Shows one Firebase service's data as a list of glass [SectionCard] groups,
/// each a set of `key -> value` rows. Loaded async; the AppBar refresh action
/// re-runs [DebugLensFirebaseService.load] so changing data (Remote Config,
/// Crashlytics, …) can be re-fetched without leaving the screen.
class FirebaseServiceScreen extends StatefulWidget {
  final DebugLensFirebaseService service;

  const FirebaseServiceScreen({super.key, required this.service});

  @override
  State<FirebaseServiceScreen> createState() => _FirebaseServiceScreenState();
}

class _FirebaseServiceScreenState extends State<FirebaseServiceScreen> {
  late Future<List<DebugLensInfoGroup>> _future = widget.service.load();

  void _reload() => setState(() => _future = widget.service.load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.name, style: monoStyle(size: 15)),
        actions: [
          IconButton(
            tooltip: DebugStrings.firebaseReload,
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<List<DebugLensInfoGroup>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error, onRetry: _reload);
          }
          final groups = snapshot.data ?? const [];
          if (groups.isEmpty) {
            return const EmptyState(
              icon: Icons.local_fire_department,
              message: DebugStrings.firebaseServiceEmpty,
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              for (final group in groups)
                SectionCard(
                  title: group.title,
                  child: group.values.isEmpty
                      ? Text(
                          DebugStrings.firebaseNone,
                          style: monoStyle(
                            size: 12,
                            color: DebugPalette.textMuted,
                          ),
                        )
                      : Column(
                          children: [
                            for (final e in group.values.entries)
                              KvRow(
                                label: e.key,
                                value: e.value,
                                sensitive: group.isSensitive(e.key),
                              ),
                          ],
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}
