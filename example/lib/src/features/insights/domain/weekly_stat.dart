import 'package:equatable/equatable.dart';

/// One progress metric on the Insights tab (pure model, [progress] is 0..1).
class WeeklyStat extends Equatable {
  const WeeklyStat({
    required this.label,
    required this.progress,
    required this.detail,
  });

  final String label;
  final double progress;
  final String detail;

  @override
  List<Object> get props => [label, progress, detail];
}
