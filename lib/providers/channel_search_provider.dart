import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/providers/playlists_provider.dart";

/// A channel with its lowercased name, so searches don't lowercase every name
/// of a large playlist on each keystroke
typedef SearchableChannel = ({Channel channel, String name});

/// All channels from all playlists, ready to search with [searchChannels]
final searchableChannelsProvider = Provider<List<SearchableChannel>>((ref) {
  final playlists = ref.watch(playlistsProvider.select((s) => s.playlists));
  return [
    for (final playlist in playlists)
      for (final channel in playlist.channels) (channel: channel, name: channel.name.toLowerCase()),
  ];
});

/// Channels whose name contains [query], ignoring case, with names that start
/// with it first. Returns nothing for an empty query.
List<Channel> searchChannels(List<SearchableChannel> channels, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return const [];

  final startsWith = <Channel>[];
  final contains = <Channel>[];
  for (final (:channel, :name) in channels) {
    if (name.startsWith(needle)) {
      startsWith.add(channel);
    } else if (name.contains(needle)) {
      contains.add(channel);
    }
  }
  return [...startsWith, ...contains];
}
