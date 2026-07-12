import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_cubit.dart';
import '../cubit/settings_cubit.dart';

/// Settings screen, opened from the AppBar gear icon.
/// The dark-mode switch actually flips the app theme via [SettingsCubit].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final cubit = context.read<SettingsCubit>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Appearance',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  title: const Text('Dark mode'),
                  subtitle: const Text('Use a dark colour scheme'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: state.darkMode,
                  onChanged: cubit.toggleDarkMode,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Language',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const _LanguageCard(),
              const SizedBox(height: 24),
              Text(
                'Preferences',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Push notifications'),
                      subtitle: const Text('Reminders and goal updates'),
                      secondary: const Icon(Icons.notifications_outlined),
                      value: state.pushEnabled,
                      onChanged: cubit.togglePush,
                    ),
                    const Divider(height: 1, indent: 56),
                    SwitchListTile(
                      title: const Text('Share analytics'),
                      subtitle: const Text('Anonymous usage statistics'),
                      secondary: const Icon(Icons.analytics_outlined),
                      value: state.analyticsEnabled,
                      onChanged: cubit.toggleAnalytics,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'About',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Version'),
                  trailing: Text('1.0.0+1'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// English / Hindi selector, driving [LocaleCubit] (which the Home tab reads
/// and the DebugLens Locale inspector mirrors).
class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LocaleCubit>().state;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          children: [
            for (final lang in AppLanguage.values)
              ChoiceChip(
                label: Text(AppStrings.label(lang)),
                selected: current == lang,
                onSelected: (_) =>
                    context.read<LocaleCubit>().setLanguage(lang),
              ),
          ],
        ),
      ),
    );
  }
}
