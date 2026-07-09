import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/debug_store.dart';
import '../theme/debug_theme.dart';
import '../widgets/debug_toast.dart';
import '../widgets/debug_widgets.dart';

/// UI-only settings. Toggles are local state for now; they will be wired to
/// capture behavior when each feature is implemented.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, bool> _capture = {
    'Network': true,
    'Logs': true,
    'Notifications': true,
    'Navigation': true,
    'Storage': true,
    'Crashes': true,
    'Analytics': true,
  };
  bool _redactHeaders = true;
  double _maxItems = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          SectionCard(
            title: 'Capture',
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
            title: 'Privacy',
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              dense: true,
              title: Text('Redact sensitive headers', style: monoStyle(size: 13)),
              subtitle: Text('Mask Authorization, cookies, tokens',
                  style: monoStyle(size: 11, color: DebugPalette.textMuted)),
              value: _redactHeaders,
              onChanged: (v) => setState(() => _redactHeaders = v),
            ),
          ),
          SectionCard(
            title: 'Buffer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Max items per type: ${_maxItems.round()}',
                    style: monoStyle(size: 13)),
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
            title: 'Data',
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: DebugPalette.error),
              title: Text('Clear all data',
                  style: monoStyle(size: 13, color: DebugPalette.error)),
              onTap: () {
                context.read<DebugStore>().clearAll();
                DebugToast.show(context, 'All in-memory data cleared');
              },
            ),
          ),
          SectionCard(
            title: 'About',
            child: Text('DebugLens · UI scaffold · v0.0.1',
                style: monoStyle(size: 12, color: DebugPalette.textMuted)),
          ),
        ],
      ),
    );
  }
}
