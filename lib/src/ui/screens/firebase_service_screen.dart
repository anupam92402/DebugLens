import 'package:flutter/material.dart';

import '../../core/debug_firebase_source.dart';
import '../theme/debug_theme.dart';
import '../widgets/debug_widgets.dart';

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
            tooltip: 'Reload',
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
            return _ErrorState(error: snapshot.error, onRetry: _reload);
          }
          final groups = snapshot.data ?? const [];
          if (groups.isEmpty) {
            return const EmptyState(
                icon: Icons.local_fire_department, message: 'No data');
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              for (final group in groups)
                SectionCard(
                  title: group.title,
                  child: group.values.isEmpty
                      ? Text('none',
                          style: monoStyle(
                              size: 12, color: DebugPalette.textMuted))
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

/// Error view with a retry action — load failures are common for live Firebase
/// wrappers (no network, not initialised, …), so make recovery one tap.
class _ErrorState extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 46, color: DebugPalette.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Failed to load\n$error',
              textAlign: TextAlign.center,
              style: monoStyle(size: 12, color: DebugPalette.textMuted),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
