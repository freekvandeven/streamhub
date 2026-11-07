import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/providers/favorites_provider.dart";
import "package:streamhub/screens/category_channels_screen.dart";

/// Favorite channels from all playlists
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CategoryChannelsScreen(
      category: ChannelCategory(name: "Favorites", channels: ref.watch(favoriteChannelsProvider)),
      emptyMessage: "No favorites yet. Tap the star next to a channel to add it here.",
    );
  }
}
