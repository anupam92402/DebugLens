import 'package:debug_lens/debug_lens.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/firebase/mock_firebase.dart';

final class SettingsState extends Equatable {
  const SettingsState({
    this.darkMode = false,
    this.pushEnabled = true,
    this.analyticsEnabled = false,
  });

  final bool darkMode;
  final bool pushEnabled;
  final bool analyticsEnabled;

  SettingsState copyWith({
    bool? darkMode,
    bool? pushEnabled,
    bool? analyticsEnabled,
  }) => SettingsState(
    darkMode: darkMode ?? this.darkMode,
    pushEnabled: pushEnabled ?? this.pushEnabled,
    analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
  );

  @override
  List<Object> get props => [darkMode, pushEnabled, analyticsEnabled];
}

/// View-model for app settings; darkMode drives [ThemeMode] at the app root.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void toggleDarkMode(bool value) {
    MockFirebase.analytics.logEvent(
      'theme_changed',
      parameters: {
        'action': value ? 'enable' : 'disable',
        'screen': 'SettingsScreen',
        'category': 'settings',
      },
    );
    DebugLensLogger().i('Dark mode ${value ? 'on' : 'off'}', name: 'settings');
    emit(state.copyWith(darkMode: value));
  }

  void togglePush(bool value) {
    MockFirebase.analytics.logEvent(
      'push_toggled',
      parameters: {
        'action': value ? 'enable' : 'disable',
        'screen': 'SettingsScreen',
        'category': 'settings',
      },
    );
    DebugLensLogger().i(
      'Push ${value ? 'enabled' : 'disabled'}',
      name: 'settings',
    );
    emit(state.copyWith(pushEnabled: value));
  }

  void toggleAnalytics(bool value) {
    MockFirebase.analytics.logEvent(
      'analytics_toggled',
      parameters: {
        'action': value ? 'enable' : 'disable',
        'screen': 'SettingsScreen',
        'category': 'settings',
      },
    );
    DebugLensLogger().i(
      'Analytics ${value ? 'enabled' : 'disabled'}',
      name: 'settings',
    );
    emit(state.copyWith(analyticsEnabled: value));
  }
}
