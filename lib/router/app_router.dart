import "package:go_router/go_router.dart";
import "package:iptv_app/screens/channels_screen.dart";
import "package:iptv_app/screens/home_screen.dart";

final router = GoRouter(
  initialLocation: "/",
  routes: [
    GoRoute(path: "/", builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: "/channels",
      builder: (context, state) => const ChannelsScreen(),
    ),
  ],
);
