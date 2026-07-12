import 'dart:ui' show Rect;

import '../../../core/debug_log_file_service.dart';
import '../../../shared/debug_strings.dart';
import '../domain/locale_data.dart';
import 'locale_log_serializer.dart';

/// Builds the locale section and shares it as a log file (`locale_logs`).
class LocaleLogShare {
  LocaleLogShare._();

  static Future<void> share(DebugLensLocaleData locale, {Rect? origin}) async {
    DebugLogFileService.instance.setSection(
      'locale',
      LocaleLogSerializer.dump(locale),
    );
    await DebugLogFileService.instance.shareLogFile(
      name: 'locale_logs',
      subject: DebugStrings.localeShareSubject,
      sharePositionOrigin: origin,
    );
  }
}
