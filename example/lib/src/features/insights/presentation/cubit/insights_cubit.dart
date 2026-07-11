import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/insights_repository.dart';
import '../../domain/weekly_stat.dart';

final class InsightsState extends Equatable {
  const InsightsState({this.loading = true, this.stats = const []});

  final bool loading;
  final List<WeeklyStat> stats;

  @override
  List<Object> get props => [loading, stats];
}

/// View-model for the Insights tab.
class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit(this._repository) : super(const InsightsState());

  final InsightsRepository _repository;

  Future<void> load() async {
    final stats = await _repository.fetchWeeklyStats();
    emit(InsightsState(loading: false, stats: stats));
  }
}
