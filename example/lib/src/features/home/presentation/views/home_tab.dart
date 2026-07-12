import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/locale_cubit.dart';
import '../../../shell/presentation/widgets/shell_app_bar_actions.dart';
import '../bloc/home_bloc.dart';
import '../widgets/activity_tile.dart';
import '../widgets/summary_card.dart';

/// Home tab root: greeting, summary cards and the recent-activity list.
/// Lives inside the Home tab's nested navigator, so it carries its own AppBar.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: const [ShellAppBarActions()],
      ),
      body: _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state.status == HomeStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final textTheme = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final l = context.l10n;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Text(
              l.greeting,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.glance,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    label: l.pending,
                    value: '${state.pendingCount}',
                    icon: Icons.pending_actions_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    label: l.completed,
                    value: '${state.completedCount}',
                    icon: Icons.task_alt_rounded,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l.recentActivity,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final activity in state.activities) ...[
              ActivityTile(activity: activity),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
