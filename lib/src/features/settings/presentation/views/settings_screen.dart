import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// UI-only settings. Toggles are local state for now; they will be wired to
/// capture behavior when each feature is implemented.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, bool> _capture = {
    DebugStrings.settingsCaptureNetwork: true,
    DebugStrings.settingsCaptureLogs: true,
    DebugStrings.settingsCaptureNotifications: true,
    DebugStrings.settingsCaptureNavigation: true,
    DebugStrings.settingsCaptureStorage: true,
    DebugStrings.settingsCaptureCrashes: true,
    DebugStrings.settingsCaptureAnalytics: true,
  };
  bool _redactHeaders = true;
  double _maxItems = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(DebugStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          SectionCard(
            title: DebugStrings.settingsCapture,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final key in _capture.keys)
                  SwitchListTile(
                    dense: true,
                    title: Text(key, style: monoStyle(size: 13)),
                    value: _capture[key]!,
                    onChanged: (v) => setState(() => _capture[key] = v),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: DebugStrings.settingsPrivacy,
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              dense: true,
              title: Text(
                DebugStrings.settingsRedactHeaders,
                style: monoStyle(size: 13),
              ),
              subtitle: Text(
                DebugStrings.settingsRedactSubtitle,
                style: monoStyle(size: 11, color: DebugColors.textMuted),
              ),
              value: _redactHeaders,
              onChanged: (v) => setState(() => _redactHeaders = v),
            ),
          ),
          SectionCard(
            title: DebugStrings.settingsBuffer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DebugStrings.settingsMaxItems(_maxItems.round()),
                  style: monoStyle(size: 13),
                ),
                Slider(
                  min: 100,
                  max: 2000,
                  divisions: 19,
                  value: _maxItems,
                  label: '${_maxItems.round()}',
                  onChanged: (v) => setState(() => _maxItems = v),
                ),
              ],
            ),
          ),
          SectionCard(
            title: DebugStrings.settingsData,
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: DebugColors.error,
              ),
              title: Text(
                DebugStrings.settingsClearAll,
                style: monoStyle(size: 13, color: DebugColors.error),
              ),
              onTap: () {
                context.read<DebugStore>().clearAll();
                DebugToast.show(context, DebugStrings.settingsClearedToast);
              },
            ),
          ),
          SectionCard(
            title: DebugStrings.settingsAbout,
            child: Text(
              DebugStrings.settingsAboutValue,
              style: monoStyle(size: 12, color: DebugColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
