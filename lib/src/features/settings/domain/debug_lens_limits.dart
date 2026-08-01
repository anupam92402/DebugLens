import 'package:flutter/foundation.dart';

import 'debug_limit.dart';

/// Starting retention limits for every captured feed, in one object.
///
/// Each feed is a ring buffer: once it holds this many records the oldest is
/// dropped. Set what your app needs and leave the rest null — a null feed keeps
/// the limit the package ships with.
///
/// ```dart
/// DebugLens.initialLimits = const DebugLensLimits(
///   network: 1000, // a session that makes a lot of calls
///   logs: 5000,
/// );
/// ```
///
/// Or one number for everything:
///
/// ```dart
/// DebugLens.initialLimits = const DebugLensLimits.all(1000);
/// ```
///
/// **Seeds the first launch only**, like `DebugLens.initialRole`: once a limit
/// has been edited from Settings on a device, the saved value wins for that feed
/// on every later launch, so raising a limit in a new release never overrides
/// what someone deliberately chose. Set it before [DebugLens.wrap] first builds.
///
/// Every value must be within [DebugLimit.min]–[DebugLimit.max]; one that isn't
/// is ignored (and asserts in debug) rather than quietly clamping to a number
/// you didn't ask for.
@immutable
class DebugLensLimits {
  /// Captured HTTP calls, with their headers and bodies.
  final int? network;

  /// Log records — also the logger's own buffer, so this is the one place to
  /// size it (it wins over `DebugLensLogger().maxHistory`).
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

  /// The same limit for every feed — for when the answer is simply "keep more".
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
  ///
  /// Read on every capture, so it stays a switch and a range check rather than
  /// building a map.
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
