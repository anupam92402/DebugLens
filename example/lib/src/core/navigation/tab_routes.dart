import 'package:flutter/material.dart';

import '../../features/home/presentation/views/activity_detail_screen.dart';
import '../../features/home/presentation/views/home_tab.dart';
import '../../features/network_demo/domain/post.dart';
import '../../features/network_demo/presentation/views/api_playground_screen.dart';
import '../../features/network_demo/presentation/views/post_detail_screen.dart';
import '../../features/network_demo/presentation/views/posts_screen.dart';

/// Single route factory shared by every tab's nested navigator. Route names
/// are namespaced per tab (`home/...`, `playground/...`), so one switch serves
/// them all — DebugLens records whatever name/arguments the settings carry.
class TabRoutes {
  TabRoutes._();

  static const String homeRoot = 'home';
  static const String activityDetail = 'home/activity-detail';
  static const String playgroundRoot = 'playground';
  static const String posts = 'playground/posts';
  static const String postDetail = 'playground/post-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = switch (settings.name) {
      activityDetail => (_) => const ActivityDetailScreen(),
      playgroundRoot => (_) => const ApiPlaygroundScreen(),
      posts => (_) => const PostsScreen(),
      // The tapped Post travels as route arguments.
      postDetail => (_) => PostDetailScreen(post: settings.arguments! as Post),
      // homeRoot — and, defensively, any unknown name.
      _ => (BuildContext _) => const HomeTab(),
    };
    return MaterialPageRoute<void>(settings: settings, builder: builder);
  }
}
