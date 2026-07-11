import 'package:flutter/material.dart';

/// Every DebugLens color (plus the mono font token) in one place — the single
/// color util the whole UI pulls from. Theme/accent logic lives elsewhere;
/// this holds only the raw values.
class DebugColors {
  DebugColors._();

  // Surfaces.
  static const bg = Color(0xFF0B1020);
  static const surface = Color(0xFF161B22); // opaque (dialogs)
  static const glassFill = Color(0x14FFFFFF);
  static const surfaceAlt = glassFill;
  static const border = Color(0x2BFFFFFF);

  // Text.
  static const textPrimary = Color(0xFFE6EDF3);
  static const textMuted = Color(0xFF9AA7B5);

  // Status.
  static const success = Color(0xFF3FD17A);
  static const error = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFC857);
  static const info = Color(0xFF5B9DFF);
  static const pending = Color(0xFF9AA7B5);

  /// Distinct hue for console-sourced logs (debugPrint / print captures).
  static const console = Color(0xFFC77DFF); // light purple

  // Per-tool accents — dashboard tiles + per-screen theming.
  static const base = Color(0xFF7C8CF8); // dashboard / fallback (indigo)
  static const network = Color(0xFF4F8CFF); // blue
  static const logs = Color(0xFF3FD17A); // green
  static const notifications = Color(0xFFFFC857); // amber
  static const navigation = Color(0xFFA78BFA); // violet
  static const bloc = Color(0xFFE11D48); // rose
  static const storage = Color(0xFF2DD4BF); // teal
  static const device = Color(0xFF22D3EE); // cyan
  static const firebase = Color(0xFFFB923C); // orange
  static const locale = Color(0xFFEC4899); // pink
  static const settings = Color(0xFF94A3B8); // slate

  /// Monospace font family used across the debug UI.
  static const mono = 'monospace';
}
