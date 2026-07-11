import '../domain/activity.dart';

/// Dummy data source for Home activities (simulates a fetch).
class ActivityRepository {
  Future<List<Activity>> fetchActivities() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return const [
      Activity(
        id: 'a1',
        title: 'Review sprint board',
        category: ActivityCategory.work,
        timeLabel: '9:15 AM',
      ),
      Activity(
        id: 'a2',
        title: 'Morning run — 5 km',
        category: ActivityCategory.fitness,
        timeLabel: '7:00 AM',
        isDone: true,
      ),
      Activity(
        id: 'a3',
        title: 'Pay electricity bill',
        category: ActivityCategory.finance,
        timeLabel: '11:30 AM',
      ),
      Activity(
        id: 'a4',
        title: 'Call plumber about kitchen sink',
        category: ActivityCategory.personal,
        timeLabel: '1:00 PM',
      ),
      Activity(
        id: 'a5',
        title: 'Ship navigation share feature',
        category: ActivityCategory.work,
        timeLabel: '3:30 PM',
      ),
      Activity(
        id: 'a6',
        title: 'Update SIP investment plan',
        category: ActivityCategory.finance,
        timeLabel: '5:00 PM',
        isDone: true,
      ),
      Activity(
        id: 'a7',
        title: 'Grocery run — weekly list',
        category: ActivityCategory.personal,
        timeLabel: '6:30 PM',
      ),
      Activity(
        id: 'a8',
        title: 'Evening stretch & mobility',
        category: ActivityCategory.fitness,
        timeLabel: '8:00 PM',
      ),
    ];
  }
}
