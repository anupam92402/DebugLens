import 'package:flutter/material.dart';

import '../../core/debug_lens_logger.dart';
import '../../core/models/bloc_event.dart';
import '../../core/models/nav_event.dart';
import '../../core/models/network_entry.dart';
import 'debug_accents.dart';

/// Fixed dark "developer console" palette used across DebugLens.
class DebugPalette {
  DebugPalette._();

  static const bg = Color(0xFF0B1020);
  static const surface = Color(0xFF161B22); // opaque (dialogs)

  // Translucent glass tokens, layered over the gradient backdrop.
  static const glassFill = Color(0x14FFFFFF);
  static const surfaceAlt = glassFill;
  static const border = Color(0x2BFFFFFF);

  static const textPrimary = Color(0xFFE6EDF3);
  static const textMuted = Color(0xFF9AA7B5);

  static const success = Color(0xFF3FD17A);
  static const error = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFC857);
  static const info = Color(0xFF5B9DFF);
  static const pending = Color(0xFF9AA7B5);

  /// Distinct hue for console-sourced logs (debugPrint / print captures) so
  /// they stand apart from custom logger records in the UI.
  static const console = Color(0xFFC77DFF); // light purple

  static const mono = 'monospace';
}

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
      dividerColor: DebugPalette.border,
      iconTheme: const IconThemeData(color: DebugPalette.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: DebugPalette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: DebugPalette.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: DebugPalette.textPrimary,
            displayColor: DebugPalette.textPrimary,
          ),
      dividerTheme: const DividerThemeData(color: DebugPalette.border, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        selectedColor: accent.withValues(alpha: 0.32),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        showCheckmark: false,
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(color: DebugPalette.textPrimary, fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: DebugPalette.textPrimary, fontSize: 12),
      ),
    );
  }
}

Color toneForStatus(NetworkStatusKind kind) {
  switch (kind) {
    case NetworkStatusKind.success:
      return DebugPalette.success;
    case NetworkStatusKind.error:
      return DebugPalette.error;
    case NetworkStatusKind.pending:
      return DebugPalette.pending;
  }
}

/// Per-method tint used by the Network list + detail screens so a glance at
/// the chip tells you whether a request is read-only, mutating, or deleting.
Color toneForMethod(HttpMethod m) {
  switch (m) {
    case HttpMethod.get:
      return DebugPalette.success;
    case HttpMethod.post:
      return DebugPalette.info;
    case HttpMethod.put:
    case HttpMethod.patch:
      return DebugPalette.warning;
    case HttpMethod.delete:
      return DebugPalette.error;
    case HttpMethod.head:
    case HttpMethod.options:
      return DebugPalette.textMuted;
  }
}

Color toneForLevel(DebugLogLevel level) {
  switch (level) {
    case DebugLogLevel.debug:
      return DebugPalette.info;
    case DebugLogLevel.info:
      return DebugPalette.success;
    case DebugLogLevel.error:
      return DebugPalette.error;
  }
}

/// Tint for a navigation action chip (push / pop / replace / remove).
Color toneForNavAction(NavAction a) {
  switch (a) {
    case NavAction.push:
      return DebugPalette.success;
    case NavAction.pop:
      return DebugPalette.info;
    case NavAction.replace:
      return DebugPalette.warning;
    case NavAction.remove:
      return DebugPalette.error;
  }
}

/// Tint for a Bloc lifecycle event chip — create (lifecycle start), close
/// (end), event (incoming), change (state moved), transition (event-driven
/// state move), error.
Color toneForBlocKind(BlocActionKind k) {
  switch (k) {
    case BlocActionKind.create:
      return DebugPalette.info;
    case BlocActionKind.close:
      return DebugPalette.textMuted;
    case BlocActionKind.event:
      return DebugPalette.warning;
    case BlocActionKind.change:
      return DebugPalette.success;
    case BlocActionKind.transition:
      return DebugAccents.navigation;
    case BlocActionKind.error:
      return DebugPalette.error;
  }
}

/// Tint for a navigation route kind chip (page / dialog / sheet / popup /
/// other). Page is muted because it's the most common — we only highlight
/// the kind chip on the tile when it's *not* a page.
Color toneForNavKind(NavRouteKind k) {
  switch (k) {
    case NavRouteKind.page:
      return DebugPalette.textMuted;
    case NavRouteKind.dialog:
      return DebugPalette.warning;
    case NavRouteKind.sheet:
      return DebugPalette.info;
    case NavRouteKind.popup:
      return DebugPalette.pending;
    case NavRouteKind.other:
      return DebugPalette.textMuted;
  }
}
