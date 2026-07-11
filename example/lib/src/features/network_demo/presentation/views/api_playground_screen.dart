import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/navigation/tab_routes.dart';
import '../../../shell/presentation/widgets/shell_app_bar_actions.dart';
import '../../domain/api_action.dart';
import '../bloc/playground/playground_bloc.dart';
import '../widgets/api_action_tile.dart';

/// API playground tab root: fires real HTTP calls (captured by the DebugLens
/// Network inspector). "Browse posts" opens a screen built from GET data;
/// the quick calls run inline and report their status.
class ApiPlaygroundScreen extends StatelessWidget {
  const ApiPlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APIs'),
        actions: const [ShellAppBarActions()],
      ),
      body: BlocProvider(
        create: (_) => sl<PlaygroundBloc>(),
        child: const _PlaygroundView(),
      ),
    );
  }
}

class _PlaygroundView extends StatelessWidget {
  const _PlaygroundView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Text(
          'Fetch & explore',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF059669).withValues(alpha: 0.12),
              child: const Icon(
                Icons.list_alt_rounded,
                color: Color(0xFF059669),
              ),
            ),
            title: const Text(
              'Browse posts',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('GET /posts → list → detail'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).pushNamed(TabRoutes.posts),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Quick calls',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final action in ApiAction.values) ...[
          ApiActionTile(action: action),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
