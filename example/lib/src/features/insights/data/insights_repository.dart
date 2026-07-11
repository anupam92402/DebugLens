import '../domain/weekly_stat.dart';

/// Dummy data source for the Insights tab.
class InsightsRepository {
  Future<List<WeeklyStat>> fetchWeeklyStats() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      WeeklyStat(label: 'Tasks completed', progress: 0.72, detail: '18 of 25'),
      WeeklyStat(label: 'Focus time', progress: 0.55, detail: '11h of 20h'),
      WeeklyStat(label: 'Workouts', progress: 0.80, detail: '4 of 5'),
      WeeklyStat(
        label: 'Budget on track',
        progress: 0.64,
        detail: '₹16k of ₹25k',
      ),
      WeeklyStat(
        label: 'Reading goal',
        progress: 0.35,
        detail: '105 of 300 pages',
      ),
    ];
  }
}
