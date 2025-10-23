import "package:go_router/go_router.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/screens/categories_screen.dart";
import "package:streamhub/screens/category_channels_screen.dart";
import "package:streamhub/screens/home_screen.dart";
import "package:streamhub/screens/loading_screen.dart";

final router = GoRouter(
  initialLocation: "/loading",
  routes: [
    GoRoute(
      path: "/loading",
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(path: "/", builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: "/categories",
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: "/category-channels",
      builder: (context, state) {
        final extra = state.extra! as Map<String, dynamic>;
        return CategoryChannelsScreen(
          categoryName: extra["categoryName"]! as String,
          channels: extra["channels"]! as List<Channel>,
        );
      },
    ),
  ],
);
