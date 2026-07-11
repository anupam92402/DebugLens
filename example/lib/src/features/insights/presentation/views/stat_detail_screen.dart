import 'package:flutter/material.dart';

import '../../domain/weekly_stat.dart';

/// Detail screen for one weekly stat, pushed on the Insights tab's NESTED
/// navigator. Receives the tapped [WeeklyStat] object itself via route
/// arguments and renders a dummy daily breakdown derived from it.
class StatDetailScreen extends StatelessWidget {
  const StatDetailScreen({super.key, required this.stat});

  final WeeklyStat stat;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  // Deterministic multipliers so the dummy per-day values follow the
  // overall weekly progress that was passed in.
  static const _dayFactors = [0.6, 0.9, 0.75, 1.0, 0.5, 0.85, 0.7];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(stat.label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: stat.progress,
                          strokeWidth: 8,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                        Center(
                          child: Text(
                            '${(stat.progress * 100).round()}%',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    stat.detail,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'of your weekly goal',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Daily breakdown',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final (index, day) in _days.indexed) ...[
                    if (index > 0) const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(day, style: textTheme.bodySmall),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (stat.progress * _dayFactors[index]).clamp(
                                0.0,
                                1.0,
                              ),
                              minHeight: 8,
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '${(stat.progress * _dayFactors[index] * 100).round()}%',
                            textAlign: TextAlign.end,
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
