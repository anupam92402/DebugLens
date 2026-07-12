import 'package:flutter/material.dart';

import '../../features/logs/domain/log_record.dart';
import '../../features/bloc/domain/bloc_event.dart';
import '../../features/navigation/domain/nav_event.dart';
import '../../features/network/domain/network_entry.dart';
import '../../features/storage/domain/pref_entry.dart';
import 'debug_colors.dart';

class DebugTheme {
  DebugTheme._();

  static ThemeData build(Color accent) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      dividerColor: DebugColors.border,
      iconTheme: const IconThemeData(color: DebugColors.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: DebugColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: DebugColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: DebugColors.textPrimary,
        displayColor: DebugColors.textPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: DebugColors.border,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        selectedColor: accent.withValues(alpha: 0.32),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        showCheckmark: false,
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          color: DebugColors.textPrimary,
          fontSize: 12,
        ),
        secondaryLabelStyle: const TextStyle(
          color: DebugColors.textPrimary,
          fontSize: 12,
        ),
      ),
    );
  }
}

Color toneForStatus(NetworkStatusKind kind) {
  switch (kind) {
    case NetworkStatusKind.success:
      return DebugColors.success;
    case NetworkStatusKind.error:
      return DebugColors.error;
    case NetworkStatusKind.pending:
      return DebugColors.pending;
  }
}

/// Per-method tint used by the Network list + detail screens so a glance at
/// the chip tells you whether a request is read-only, mutating, or deleting.
Color toneForMethod(HttpMethod m) {
  switch (m) {
    case HttpMethod.get:
      return DebugColors.success;
    case HttpMethod.post:
      return DebugColors.info;
    case HttpMethod.put:
    case HttpMethod.patch:
      return DebugColors.warning;
    case HttpMethod.delete:
      return DebugColors.error;
    case HttpMethod.head:
    case HttpMethod.options:
      return DebugColors.textMuted;
  }
}

/// Tint for a SharedPreferences type chip (bool / int / double / …).
Color toneForPrefType(DebugLensPrefType type) {
  switch (type) {
    case DebugLensPrefType.boolean:
      return DebugColors.warning;
    case DebugLensPrefType.integer:
      return DebugColors.info;
    case DebugLensPrefType.double:
      return DebugColors.success;
    case DebugLensPrefType.string:
      return DebugColors.console;
    case DebugLensPrefType.stringList:
      return DebugColors.storage;
    case DebugLensPrefType.unknown:
      return DebugColors.textMuted;
  }
}

Color toneForLevel(DebugLogLevel level) {
  switch (level) {
    case DebugLogLevel.debug:
      return DebugColors.info;
    case DebugLogLevel.info:
      return DebugColors.success;
    case DebugLogLevel.error:
      return DebugColors.error;
  }
}

/// Tint for a navigation action chip (push / pop / replace / remove).
Color toneForNavAction(NavAction a) {
  switch (a) {
    case NavAction.push:
      return DebugColors.success;
    case NavAction.pop:
      return DebugColors.info;
    case NavAction.replace:
      return DebugColors.warning;
    case NavAction.remove:
      return DebugColors.error;
  }
}

/// Tint for a Bloc lifecycle event chip — create (lifecycle start), close
/// (end), event (incoming), change (state moved), transition (event-driven
/// state move), error.
Color toneForBlocKind(BlocActionKind k) {
  switch (k) {
    case BlocActionKind.create:
      return DebugColors.info;
    case BlocActionKind.close:
      return DebugColors.textMuted;
    case BlocActionKind.event:
      return DebugColors.warning;
    case BlocActionKind.change:
      return DebugColors.success;
    case BlocActionKind.transition:
      return DebugColors.navigation;
    case BlocActionKind.error:
      return DebugColors.error;
  }
}

/// Tint for a navigation route kind chip (page / dialog / sheet / popup /
/// other). Page is muted because it's the most common — we only highlight
/// the kind chip on the tile when it's *not* a page.
Color toneForNavKind(NavRouteKind k) {
  switch (k) {
    case NavRouteKind.page:
      return DebugColors.textMuted;
    case NavRouteKind.dialog:
      return DebugColors.warning;
    case NavRouteKind.sheet:
      return DebugColors.info;
    case NavRouteKind.popup:
      return DebugColors.pending;
    case NavRouteKind.other:
      return DebugColors.textMuted;
  }
}
