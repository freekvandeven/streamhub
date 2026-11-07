import "dart:async";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/providers/playlists_provider.dart";
import "package:streamhub/services/favorites_storage.dart";
import "package:streamhub/utils/logger.dart";

/// Favorite channel keys (see [Channel.favoriteKey]) in the order they were added
class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    unawaited(_loadFromStorage());
    return const {};
  }

  Future<void> _loadFromStorage() async {
    try {
      final keys = await FavoritesStorage.load();
      // Keep anything toggled while loading
      state = {...keys, ...state};
    } on Exception catch (e) {
      Logger.error("Failed to load favorites: $e");
    }
  }

  /// Adds [channel] to the favorites, or removes it if it's already there
  Future<void> toggle(Channel channel) async {
    final key = channel.favoriteKey;
    state = state.contains(key) ? ({...state}..remove(key)) : {...state, key};
    await FavoritesStorage.save(state);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

/// Favorite channels from all playlists, in the order they were added. A
/// channel that's in several playlists is listed once.
final favoriteChannelsProvider = Provider<List<Channel>>((ref) {
  final keys = ref.watch(favoritesProvider);
  if (keys.isEmpty) return const [];

  final channelsByKey = <String, Channel>{};
  for (final playlist in ref.watch(playlistsProvider.select((s) => s.playlists))) {
    for (final channel in playlist.channels) {
      if (keys.contains(channel.favoriteKey)) {
        channelsByKey.putIfAbsent(channel.favoriteKey, () => channel);
      }
    }
  }

  return [for (final key in keys) ?channelsByKey[key]];
});
