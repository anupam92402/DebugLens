import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../firebase/mock_firebase.dart';
import 'app_strings.dart';

/// Holds the current app language (English / Hindi).
class LocaleCubit extends Cubit<AppLanguage> {
  LocaleCubit() : super(AppLanguage.en);

  void setLanguage(AppLanguage lang) {
    MockFirebase.analytics.logEvent(
      'language_changed',
      parameters: {
        'locale': lang.name,
        'screen': 'SettingsScreen',
        'category': 'settings',
      },
    );
    debugLog.i('Language switched to ${lang.name}', name: 'locale');
    emit(lang);
  }
}

/// Convenience: the current language's [L10n] accessor, rebuilding on change.
extension LocaleContext on BuildContext {
  L10n get l10n => L10n(watch<LocaleCubit>().state);
}
