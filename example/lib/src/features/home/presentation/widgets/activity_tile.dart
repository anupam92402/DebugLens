import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/tab_routes.dart';
import '../../domain/activity.dart';
import '../bloc/home_bloc.dart';
import 'activity_options_sheet.dart';
import 'category_style.dart';

/// One activity row: category avatar, title, time, done-toggle.
/// Tapping pushes the detail screen on the tab's nested navigator; long-press
/// opens the options bottom sheet.
class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final category = activity.category;
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).pushNamed(
          TabRoutes.activityDetail,
          arguments: {'id': activity.id, 'title': activity.title},
        ),
        onLongPress: () => ActivityOptionsSheet.show(context, activity),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: category.color.withValues(alpha: 0.12),
          child: Icon(category.icon, color: category.color, size: 20),
        ),
        title: Text(
          activity.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: activity.isDone ? TextDecoration.lineThrough : null,
            color: activity.isDone ? scheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Text('${category.label} · ${activity.timeLabel}'),
        trailing: IconButton(
          tooltip: activity.isDone ? 'Mark as pending' : 'Mark as done',
          icon: Icon(
            activity.isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: activity.isDone ? const Color(0xFF059669) : scheme.outline,
          ),
          onPressed: () =>
              context.read<HomeBloc>().add(HomeActivityToggled(activity.id)),
        ),
      ),
    );
  }
}
