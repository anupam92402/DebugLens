import 'package:flutter_bloc/flutter_bloc.dart';

/// View-model for the app shell: which bottom-nav tab is selected.
class ShellCubit extends Cubit<int> {
  ShellCubit() : super(0);

  void select(int index) => emit(index);
}
