import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../data/debug_analytics_store.dart';
import '../../data/debug_service_source.dart';
import 'service_detail_screen.dart';

/// The Analytics tab: recorded analytics events, under the name the host gave
/// `DebugLens.initAnalytics`, or the default before it has been called.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service =
        DebugLensServices.services
            .whereType<DebugAnalyticsService>()
            .firstOrNull ??
        DebugAnalyticsService(name: DebugStrings.serviceAnalyticsName);
    return ServiceDetailScreen(service: service);
  }
}
