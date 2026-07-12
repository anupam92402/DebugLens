import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/app.dart';
import 'src/core/di/service_locator.dart';

void main() {
  // Feed every cubit/bloc in the app into the DebugLens Bloc inspector.
  Bloc.observer = DebugLensBlocObserver();
  setupLocator();
  runApp(const ExampleApp());
}
