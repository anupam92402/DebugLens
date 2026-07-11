import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/di/service_locator.dart';

void main() {
  setupLocator();
  runApp(const ExampleApp());
}
