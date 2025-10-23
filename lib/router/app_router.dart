import "package:go_router/go_router.dart";
import "package:streamhub/screens/channels_screen.dart";
import "package:streamhub/screens/home_screen.dart";

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
