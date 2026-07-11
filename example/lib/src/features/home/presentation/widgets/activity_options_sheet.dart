import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/activity.dart';
import '../bloc/home_bloc.dart';
import 'category_style.dart';
import 'delete_activity_dialog.dart';

/// Options bottom sheet for one activity (long-press a tile). Pushed as a
/// named [ModalBottomSheetRoute], so the DebugLens navigation inspector shows
/// it as a `sheet` kind; its Delete action then opens [DeleteActivityDialog]
/// (a `dialog` kind).
class ActivityOptionsSheet extends StatelessWidget {
  const ActivityOptionsSheet({super.key, required this.activity});

  final Activity activity;

  static Future<void> show(BuildContext context, Activity activity) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      routeSettings: const RouteSettings(name: 'home/activity-options-sheet'),
      builder: (_) => ActivityOptionsSheet(activity: activity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = activity.isDone;
    final category = activity.category;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: category.color.withValues(alpha: 0.12),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            title: Text(
              activity.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('${category.label} · ${activity.timeLabel}'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(done ? Icons.undo_rounded : Icons.task_alt_rounded),
            title: Text(done ? 'Mark as pending' : 'Mark as done'),
            onTap: () {
              context.read<HomeBloc>().add(HomeActivityToggled(activity.id));
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFDC2626),
            ),
            title: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
            onTap: () async {
              // Capture before the await so we don't use context across the
              // async gap.
              final bloc = context.read<HomeBloc>();
              final navigator = Navigator.of(context);
              final confirmed = await DeleteActivityDialog.show(
                context,
                activity.title,
              );
              if (confirmed == true) {
                bloc.add(HomeActivityDeleted(activity.id));
                navigator.pop();
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
