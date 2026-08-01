import 'package:flutter/foundation.dart';

import 'debug_limit.dart';

/// How many records each captured feed keeps, in one object.
///
/// A null feed keeps the shipped limit; every value must be within
/// [DebugLimit.min]–[DebugLimit.max], and one that isn't is ignored.
///
/// ```dart
/// DebugLens.initialLimits = const DebugLensLimits(network: 1000, logs: 5000);
/// DebugLens.initialLimits = const DebugLensLimits.all(1000);
/// ```
@immutable
class DebugLensLimits {
  /// Captured HTTP calls, with their headers and bodies.
  final int? network;

  /// Log records; also sizes the logger's own buffer.
  final int? logs;

  /// Push and local notifications.
  final int? notifications;

  /// Captured deep links.
  final int? deeplinks;

  /// Bloc/cubit lifecycle events.
  final int? bloc;

  /// Route events — pushes, pops, replaces, removes.
  final int? navigation;

  /// Crashes and non-fatals pushed in through `recordCrash`.
  final int? crashes;

  /// Analytics events pushed in through `recordAnalyticsEvent`.
  final int? analytics;

  /// Finished traces pushed in through `recordTrace`.
  final int? traces;

  const DebugLensLimits({
    this.network,
    this.logs,
    this.notifications,
    this.deeplinks,
    this.bloc,
    this.navigation,
    this.crashes,
    this.analytics,
    this.traces,
  });

  /// The same limit for every feed.
  const DebugLensLimits.all(int limit)
    : network = limit,
      logs = limit,
      notifications = limit,
      deeplinks = limit,
      bloc = limit,
      navigation = limit,
      crashes = limit,
      analytics = limit,
      traces = limit;

  /// The limit set for [limit], or null to leave it at its shipped default.
  int? valueOf(DebugLimit limit) {
    final value = switch (limit) {
      DebugLimit.network => network,
      DebugLimit.logs => logs,
      DebugLimit.notifications => notifications,
      DebugLimit.deeplinks => deeplinks,
      DebugLimit.bloc => bloc,
      DebugLimit.navigation => navigation,
      DebugLimit.crashes => crashes,
      DebugLimit.analytics => analytics,
      DebugLimit.traces => traces,
    };
    if (value == null) return null;
    assert(
      DebugLimit.accepts(value),
      'DebugLensLimits.${limit.name} must be between ${DebugLimit.min} and '
      '${DebugLimit.max}, got $value',
    );
    return DebugLimit.accepts(value) ? value : null;
  }
}
