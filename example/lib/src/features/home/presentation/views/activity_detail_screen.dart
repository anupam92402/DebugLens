import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/activity.dart';
import '../bloc/home_bloc.dart';
import '../widgets/category_style.dart';

/// Detail screen for one activity, pushed on the Home tab's NESTED navigator
/// (bottom bar + FAB stay visible).
///
/// Data passing: only the activity id travels in the route arguments
/// (`{'id': ..., 'title': ...}` — visible in the DebugLens Navigation
/// inspector); the full [Activity] is looked up live from [HomeBloc], so the
/// done-toggle below updates both this screen and the Home list.
class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final id = args is Map ? args['id'] as String? : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final matches = state.activities.where((a) => a.id == id);
          if (matches.isEmpty) {
            return const Center(child: Text('Activity not found'));
          }
          final activity = matches.first;
          return _ActivityDetailBody(activity: activity);
        },
      ),
    );
  }
}

class _ActivityDetailBody extends StatelessWidget {
  const _ActivityDetailBody({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final category = activity.category;
    final done = activity.isDone;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: category.color.withValues(alpha: 0.12),
                  child: Icon(category.icon, color: category.color, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  activity.title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(done ? 'Completed' : 'Pending'),
                  labelStyle: TextStyle(
                    color: done ? const Color(0xFF059669) : scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor:
                      (done ? const Color(0xFF059669) : scheme.primary)
                          .withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(category.icon, color: category.color),
                title: const Text('Category'),
                trailing: Text(category.label),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Scheduled'),
                trailing: Text(activity.timeLabel),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.tag_rounded),
                title: const Text('ID'),
                trailing: Text(activity.id),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () =>
              context.read<HomeBloc>().add(HomeActivityToggled(activity.id)),
          icon: Icon(done ? Icons.undo_rounded : Icons.task_alt_rounded),
          label: Text(done ? 'Mark as pending' : 'Mark as done'),
        ),
      ],
    );
  }
}
