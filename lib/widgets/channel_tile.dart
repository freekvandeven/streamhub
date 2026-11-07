import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/providers/favorites_provider.dart";
import "package:streamhub/widgets/channel_logo.dart";

/// A channel in a list: tap to play, with a star to toggle it as a favorite
class ChannelTile extends ConsumerWidget {
  const ChannelTile({required this.channel, required this.subtitle, super.key});

  final Channel channel;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesProvider.select((favorites) => favorites.contains(channel.favoriteKey)),
    );

    return ListTile(
      leading: ChannelLogo(url: channel.tvgLogo, size: 48),
      title: Text(channel.name),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      trailing: FavoriteButton(channel: channel, isFavorite: isFavorite),
      onTap: () => context.push("/video-player", extra: channel),
    );
  }
}

/// Star button that toggles [channel] as a favorite
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    required this.channel,
    required this.isFavorite,
    this.color,
    super.key,
  });

  final Channel channel;
  final bool isFavorite;

  /// Color of the outline star when [channel] isn't a favorite
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? Colors.amber : color,
      ),
      tooltip: isFavorite ? "Remove from favorites" : "Add to favorites",
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(channel),
    );
  }
}
