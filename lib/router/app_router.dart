import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/screens/category_channels_screen.dart";
import "package:streamhub/screens/home_screen.dart";
import "package:streamhub/screens/playlist_settings_screen.dart";
import "package:streamhub/screens/settings_screen.dart";
import "package:streamhub/screens/video_player_screen.dart";

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(path: "/", builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: "/settings",
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: "/settings/playlists",
        builder: (context, state) => const PlaylistSettingsScreen(),
      ),
      // The routes below receive their data through `extra`, which is lost
      // when the page is reloaded on web, so fall back to the home screen.
      GoRoute(
        path: "/category-channels",
        redirect: (context, state) =>
            state.extra is ChannelCategory ? null : "/",
        builder: (context, state) => CategoryChannelsScreen(
          category: state.extra! as ChannelCategory,
        ),
      ),
      GoRoute(
        path: "/video-player",
        redirect: (context, state) => state.extra is Channel ? null : "/",
        builder: (context, state) =>
            VideoPlayerScreen(channel: state.extra! as Channel),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
