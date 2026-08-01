import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_role.dart';
import '../../../health/data/health_check_store.dart';
import '../../../health/presentation/widgets/health_reports_sheet.dart';
import '../../../../core/debug_store.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shell/debug_routes.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../data/app_version_store.dart';
import '../../data/bubble_store.dart';
import '../../data/debug_limits_store.dart';
import '../../domain/debug_limit.dart';
import '../widgets/app_version_dialog.dart';
import '../widgets/bubble_sheet.dart';
import '../widgets/clear_data_dialog.dart';
import '../widgets/error_screen_dialog.dart';
import '../widgets/limits_sheet.dart';
import '../widgets/role_sheet.dart';
import '../widgets/tester_access_sheet.dart';

/// Panel settings: the access role, what a tester may open, how much of each
/// feed is retained, and the one destructive action.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<DebugRoleController>();
    return Scaffold(
      appBar: AppBar(title: const Text(DebugStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          SectionCard(
            title: DebugStrings.settingsAccess,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tile(
                  icon: Icons.badge_outlined,
                  title: DebugStrings.settingsMode,
                  value: role.isDeveloper
                      ? DebugStrings.roleDeveloper
                      : DebugStrings.roleTester,
                  onTap: () => RoleSheet.show(context),
                ),
                // Developer-only. The screen stays mounted after stepping down
                // to tester, and granting access is not a tester's call.
                if (role.isDeveloper) ...[
                  const Divider(height: 1, color: DebugColors.border),
                  _tile(
                    icon: Icons.lock_open_outlined,
                    title: DebugStrings.settingsTesterAccess,
                    value: DebugStrings.settingsTesterAccessCount(
                      role.testerRoutes.length,
                    ),
                    enabled: role.testerEnabled,
                    onTap: role.testerEnabled
                        ? () => TesterAccessSheet.show(context)
                        : () => DebugToast.show(
                            context,
                            DebugStrings.settingsTesterDisabledToast,
                          ),
                  ),
                ],
              ],
            ),
          ),
          SectionCard(
            title: DebugStrings.settingsBuffer,
            padding: EdgeInsets.zero,
            child: ListenableBuilder(
              listenable: DebugLimits.instance,
              builder: (context, _) => _tile(
                icon: Icons.data_usage,
                title: DebugStrings.settingsLimits,
                value: DebugStrings.settingsLimitsCount(
                  DebugLimit.values.where(DebugLimits.instance.isCustom).length,
                ),
                onTap: () => LimitsSheet.show(context),
              ),
            ),
          ),
          SectionCard(
            title: DebugStrings.settingsApp,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListenableBuilder(
                  listenable: BubbleStore.instance,
                  builder: (context, _) {
                    final bubble = BubbleStore.instance;
                    return _tile(
                      icon: Icons.adjust,
                      // The chosen mark itself, which for the Flutter logo
                      // isn't an `IconData` at all.
                      leading: bubble.icon.glyph(
                        size: 20,
                        color: DebugColors.textPrimary,
                      ),
                      title: DebugStrings.settingsBubble,
                      value: bubble.corner.label,
                      onTap: () => BubbleSheet.show(context),
                    );
                  },
                ),
                const Divider(height: 1, color: DebugColors.border),
                ListenableBuilder(
                  listenable: AppVersionStore.instance,
                  builder: (context, _) {
                    final store = AppVersionStore.instance;
                    return _tile(
                      icon: Icons.info_outline,
                      title: DebugStrings.settingsAppVersion,
                      // The version in force now — an edit shows in the
                      // subtitle until a restart makes it the real one.
                      value: store.version.isEmpty
                          ? DebugConstants.emptyValue
                          : store.version,
                      subtitle: store.awaitingRestart
                          ? '${store.pending} · '
                                '${DebugStrings.appVersionPending}'
                          : null,
                      onTap: () => showAppVersionDialog(context),
                    );
                  },
                ),
                const Divider(height: 1, color: DebugColors.border),
                // Documents the hook rather than toggling it — installing
                // `ErrorWidget.builder` is the host's call, not the panel's.
                _tile(
                  icon: Icons.report_gmailerrorred_outlined,
                  title: DebugStrings.settingsErrorScreen,
                  value: DebugStrings.settingsErrorScreenSetup,
                  onTap: () => showErrorScreenDialog(context),
                ),
                const Divider(height: 1, color: DebugColors.border),
                // Two taps: the first opens a window, the second closes it and
                // shows what failed inside. Running state is on the row itself
                // — a check is easy to forget you started.
                ListenableBuilder(
                  listenable: HealthCheckStore.instance,
                  builder: (context, _) {
                    final health = HealthCheckStore.instance;
                    final startedAt = health.startedAt;
                    return Column(
                      children: [
                        _tile(
                          icon: startedAt == null
                              ? Icons.monitor_heart_outlined
                              : Icons.stop_circle_outlined,
                          title: DebugStrings.settingsHealthCheck,
                          // The value says what a tap does; the subtitle says
                          // what state it is in.
                          value: startedAt == null
                              ? DebugStrings.settingsHealthStart
                              : DebugStrings.settingsHealthStop,
                          subtitle: startedAt == null
                              ? null
                              : DebugStrings.settingsHealthTracking(
                                  ClockFormat.clock(startedAt),
                                ),
                          onTap: () => _toggleHealthCheck(context),
                        ),
                        if (health.hasReports) ...[
                          const Divider(height: 1, color: DebugColors.border),
                          _tile(
                            icon: Icons.history,
                            title: DebugStrings.settingsHealthPrevious,
                            value: DebugStrings.settingsHealthPreviousCount(
                              health.reports.length,
                            ),
                            onTap: () => HealthReportsSheet.show(context),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          SectionCard(
            title: DebugStrings.settingsData,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: DebugColors.error,
                  ),
                  title: Text(
                    DebugStrings.settingsClearAll,
                    style: monoStyle(size: 13, color: DebugColors.error),
                  ),
                  onTap: () async {
                    final confirmed = await showClearDataDialog(context);
                    if (confirmed != true || !context.mounted) return;
                    context.read<DebugStore>().clearAll();
                    DebugToast.show(context, DebugStrings.settingsClearedToast);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// First tap opens the window, second closes it and pushes the report.
  void _toggleHealthCheck(BuildContext context) {
    final health = HealthCheckStore.instance;
    if (!health.isRunning) {
      health.start();
      DebugToast.show(context, DebugStrings.settingsHealthStartedToast);
      return;
    }
    final report = health.stop();
    if (report == null) return;
    Navigator.of(
      context,
    ).pushNamed(DebugRoutes.healthReport, arguments: report);
  }

  /// Navigation-style row: what it is on the left, its current value on the
  /// right, opening a sheet on tap.
  Widget _tile({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    VoidCallback? onTap,
    bool enabled = true,
    Widget? leading,
  }) {
    final tone = enabled ? DebugColors.textPrimary : DebugColors.textMuted;
    return ListTile(
      // [leading] wins when a row's mark isn't a font glyph.
      leading: leading ?? Icon(icon, size: 20, color: tone),
      title: Text(title, style: monoStyle(size: 13, color: tone)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: monoStyle(size: 11, color: DebugColors.textMuted),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: monoStyle(size: 12, color: DebugColors.textMuted)),
          if (enabled && onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
