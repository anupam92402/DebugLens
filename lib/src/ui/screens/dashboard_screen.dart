import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/debug_lens_controller.dart';
import '../../core/debug_role.dart';
import '../../routing/debug_routes.dart';
import '../theme/debug_accents.dart';
import '../theme/debug_theme.dart';
import '../widgets/debug_widgets.dart';
import '../widgets/glass.dart';
import '../widgets/matrix_rain.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _items = <_DashItem>[
    _DashItem(Icons.language, 'Network', DebugRoutes.network),
    _DashItem(Icons.notes, 'Logs', DebugRoutes.logs),
    _DashItem(
      Icons.notifications_outlined,
      'Notif / Deeplink',
      DebugRoutes.notifications,
    ),
    _DashItem(Icons.alt_route, 'Navigation', DebugRoutes.navigation),
    _DashItem(Icons.stream, 'Bloc', DebugRoutes.bloc),
    _DashItem(Icons.storage, 'Storage', DebugRoutes.storage),
    _DashItem(Icons.phone_iphone, 'Device & App', DebugRoutes.device),
    _DashItem(Icons.local_fire_department, 'Firebase', DebugRoutes.firebase),
    _DashItem(Icons.translate, 'Locale', DebugRoutes.locale),
    _DashItem(Icons.settings, 'Settings', DebugRoutes.settings),
  ];

  Future<void> _toggleRole(BuildContext context) async {
    final roleController = context.read<DebugRoleController>();
    // Switching INTO developer requires the password; leaving it is free.
    if (!roleController.isDeveloper) {
      final unlocked = await showDialog<bool>(
        context: context,
        builder: (_) => const _DeveloperPasswordDialog(),
      );
      if (unlocked != true) return;
    }
    if (!context.mounted) return;
    await roleController.toggle();
    if (!context.mounted) return;
    // Matrix-style "transformation" flourish announcing the new role.
    MatrixRain.show(
      context,
      label: roleController.isDeveloper ? 'DEVELOPER' : 'TESTER',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDeveloper = context.watch<DebugRoleController>().isDeveloper;
    // Testers can only open Network; developers see everything.
    final items = isDeveloper
        ? _items
        : _items.where((i) => i.route == DebugRoutes.network).toList();

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          // Long-press the title to switch role (tester ↔ developer).
          onLongPress: () => _toggleRole(context),
          child: const Text('🔍 DebugLens'),
        ),
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => context.read<DebugLensController>().close(),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [for (final item in items) _DashCard(item: item)],
      ),
    );
  }
}

class _DashItem {
  final IconData icon;
  final String title;
  final String route;

  const _DashItem(this.icon, this.title, this.route);

  Color get color => DebugAccents.forRoute(route);
}

class _DashCard extends StatelessWidget {
  final _DashItem item;

  const _DashCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.color;
    return GlassSurface(
      radius: 18,
      tint: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).pushNamed(item.route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: color, size: 22),
              ),
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Password gate shown before switching to developer mode. Pops `true` on the
/// correct password, `false`/`null` otherwise.
class _DeveloperPasswordDialog extends StatefulWidget {
  const _DeveloperPasswordDialog();

  @override
  State<_DeveloperPasswordDialog> createState() =>
      _DeveloperPasswordDialogState();
}

class _DeveloperPasswordDialogState extends State<_DeveloperPasswordDialog> {
  static const String _password = '123456';

  final TextEditingController _controller = TextEditingController();
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text == _password) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DebugPalette.surface,
      title: Text('Developer access', style: monoStyle(size: 15)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        style: monoStyle(size: 14),
        onChanged: (_) {
          if (_error) setState(() => _error = false);
        },
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'Enter password',
          errorText: _error ? 'Incorrect password' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}
