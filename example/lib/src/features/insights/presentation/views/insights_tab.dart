import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shell/presentation/widgets/shell_app_bar_actions.dart';
import '../cubit/insights_cubit.dart';
import '../widgets/stat_bar.dart';

/// Insights tab root: weekly progress overview built from dummy stats.
/// Lives inside the Insights tab's nested navigator, so it carries its own
/// AppBar.
class InsightsTab extends StatelessWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: const [ShellAppBarActions()],
      ),
      body: _InsightsBody(),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InsightsCubit, InsightsState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final textTheme = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final average = state.stats.isEmpty
            ? 0.0
            : state.stats.map((stat) => stat.progress).reduce((a, b) => a + b) /
                  state.stats.length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: average,
                            strokeWidth: 6,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                          Center(
                            child: Text(
                              '${(average * 100).round()}%',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly summary',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You are on track across most goals this week.',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'This week',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final stat in state.stats) ...[
              StatBar(stat: stat),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
