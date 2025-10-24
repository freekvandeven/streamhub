import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/providers/init_provider.dart";
import "package:streamhub/screens/categories_screen.dart";
import "package:streamhub/screens/category_channels_screen.dart";
import "package:streamhub/screens/home_screen.dart";
import "package:streamhub/screens/loading_screen.dart";
import "package:streamhub/screens/playlist_settings_screen.dart";
import "package:streamhub/screens/settings_screen.dart";

final routerProvider = Provider<GoRouter>((ref) {
  final isInitialized = ref.watch(initializationProvider);

  return GoRouter(
    initialLocation: "/",
    redirect: (context, state) {
      // If not initialized and not on loading screen, redirect to loading
      if (!isInitialized && state.matchedLocation != "/loading") {
        return "/loading";
      }
      // If initialized and on loading screen, redirect to home
      if (isInitialized && state.matchedLocation == "/loading") {
        return "/";
      }
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: "/loading",
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(path: "/", builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: "/settings",
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: "/settings/playlists",
        builder: (context, state) => const PlaylistSettingsScreen(),
      ),
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
});
