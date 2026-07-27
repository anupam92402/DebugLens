import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/firebase/mock_firebase.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_cubit.dart';
import '../../../../core/notifications/notification_service.dart';
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
                'Notifications',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const _NotificationsCard(),
              const SizedBox(height: 24),
              Text(
                'Diagnostics',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const _DiagnosticsCard(),
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
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Version'),
                  // Read through DebugLens rather than hardcoded, so a version
                  // overridden in the panel shows here after a restart.
                  trailing: Text(DebugLens.instance.appVersion),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Fires a batch of on-device local notifications for the demo.
class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard();

  @override
  Widget build(BuildContext context) {
    final service = sl<NotificationService>();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: const Text('Send test notifications'),
        subtitle: Text('Fires ${service.sampleCount} on-device notifications'),
        trailing: const Icon(Icons.send_rounded),
        onTap: () async {
          await service.triggerSamples();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Sent ${service.sampleCount} notifications'),
              ),
            );
        },
      ),
    );
  }
}

/// Ways to make the app misbehave on purpose: two Crashlytics severities for
/// the crash inspector, and a real build failure for the error screen.
class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard();

  /// Throws and catches on the spot, so the report carries a real stack trace.
  void _record(BuildContext context, {required bool fatal}) {
    final label = fatal ? 'fatal' : 'non-fatal';
    try {
      throw StateError('Simulated $label from Settings');
    } catch (e, stack) {
      MockFirebase.crashlytics.recordError(
        error: e,
        stackTrace: stack,
        fatal: fatal,
        reason: 'User tapped "Simulate $label error"',
      );
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Recorded a $label report')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Simulate non-fatal error'),
            subtitle: const Text('Records a Crashlytics non-fatal report'),
            trailing: const Icon(Icons.warning_amber_rounded),
            onTap: () => _record(context, fatal: false),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.dangerous_outlined),
            title: const Text('Simulate fatal error'),
            subtitle: const Text('Records a Crashlytics fatal report'),
            trailing: const Icon(Icons.error_outline),
            onTap: () => _record(context, fatal: true),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.broken_image_outlined),
            title: const Text('Simulate build error'),
            subtitle: const Text(
              "Throws while building, to show DebugLens's "
              'error screen',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const _BrokenScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hosts [_BrokenBody] under a normal AppBar.
///
/// The throw is deliberately one level down rather than here: `ErrorWidget`
/// replaces only the widget that failed, so keeping the Scaffold intact leaves
/// a back button and shows the error screen where a real broken widget would
/// appear — inside the page, not instead of it.
class _BrokenScreen extends StatelessWidget {
  const _BrokenScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulated build error')),
      body: const _BrokenBody(),
    );
  }
}

class _BrokenBody extends StatelessWidget {
  const _BrokenBody();

  @override
  Widget build(BuildContext context) {
    throw StateError('Simulated build failure from Settings');
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
