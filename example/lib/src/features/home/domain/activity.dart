import 'package:equatable/equatable.dart';

enum ActivityCategory { work, personal, fitness, finance }

/// A single activity/task shown on the Home tab (pure model).
class Activity extends Equatable {
  const Activity({
    required this.id,
    required this.title,
    required this.category,
    required this.timeLabel,
    this.isDone = false,
  });

  final String id;
  final String title;
  final ActivityCategory category;
  final String timeLabel;
  final bool isDone;

  Activity copyWith({bool? isDone}) => Activity(
    id: id,
    title: title,
    category: category,
    timeLabel: timeLabel,
    isDone: isDone ?? this.isDone,
  );

  @override
  List<Object> get props => [id, title, category, timeLabel, isDone];
}
