import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/providers/channel_search_provider.dart";
import "package:streamhub/providers/favorites_provider.dart";
import "package:streamhub/providers/playlists_provider.dart";
import "package:streamhub/utils/formatting.dart";
import "package:streamhub/widgets/channel_tile.dart";

/// What the home screen search looks through
enum _SearchMode { categories, channels }

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsState = ref.watch(playlistsProvider);
    final playlists = playlistsState.playlists;
    final favoriteCount = ref.watch(favoriteChannelsProvider).length;
    final searchQuery = useState("");
    final searchMode = useState(_SearchMode.categories);
    final searchingChannels = searchMode.value == _SearchMode.channels;

    // Group channels from all playlists by category, largest first
    final categories = useMemoized(() {
      final groups = <String, List<Channel>>{};
      for (final playlist in playlists) {
        for (final channel in playlist.channels) {
          (groups[channel.groupTitle ?? "Uncategorized"] ??= []).add(channel);
        }
      }

      return [
        for (final MapEntry(key: name, value: channels) in groups.entries)
          ChannelCategory(name: name, channels: channels),
      ]..sort((a, b) => b.channels.length.compareTo(a.channels.length));
    }, [playlists]);

    final channelCount = useMemoized(
      () => categories.fold(0, (sum, c) => sum + c.channels.length),
      [categories],
    );

    // Filter categories based on search
    final filteredCategories = useMemoized(() {
      final query = searchQuery.value.trim().toLowerCase();
      if (query.isEmpty) return categories;
      return categories.where((c) => c.name.toLowerCase().contains(query)).toList();
    }, [categories, searchQuery.value]);

    // Channels in all playlists matching the search
    final searchableChannels = ref.watch(searchableChannelsProvider);
    final matchingChannels = useMemoized(
      () => searchingChannels ? searchChannels(searchableChannels, searchQuery.value) : const <Channel>[],
      [searchableChannels, searchQuery.value, searchingChannels],
    );

    final Widget content;
    if (playlistsState.isLoading && channelCount == 0) {
      content = const Center(child: CircularProgressIndicator());
    } else if (channelCount == 0) {
      content = const _EmptyState();
    } else if (searchingChannels) {
      content = _ChannelResults(
        channels: matchingChannels,
        hasQuery: searchQuery.value.trim().isNotEmpty,
      );
    } else {
      // Favorites come first, unless searching for a category
      final showFavorites = searchQuery.value.trim().isEmpty;
      final offset = showFavorites ? 1 : 0;
      content = ListView.builder(
        itemCount: filteredCategories.length + offset,
        itemBuilder: (context, index) => showFavorites && index == 0
            ? _FavoritesTile(count: favoriteCount)
            : _CategoryTile(category: filteredCategories[index - offset]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("StreamHub"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.splitscreen),
            tooltip: "Split screen",
            onPressed: () => context.push("/multi-view", extra: <Channel>[]),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push("/settings"),
            tooltip: "Settings",
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: searchingChannels ? "Search all channels..." : "Search categories...",
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => searchQuery.value = value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_SearchMode>(
                segments: const [
                  ButtonSegment(
                    value: _SearchMode.categories,
                    icon: Icon(Icons.category),
                    label: Text("Categories"),
                    tooltip: "Search category names",
                  ),
                  ButtonSegment(
                    value: _SearchMode.channels,
                    icon: Icon(Icons.tv),
                    label: Text("Channels"),
                    tooltip: "Search channel names in all playlists",
                  ),
                ],
                selected: {searchMode.value},
                onSelectionChanged: (selection) => searchMode.value = selection.first,
              ),
            ),
          ),

          // Summary stats
          if (channelCount > 0 && !searchingChannels)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat(
                        value: playlists.length,
                        label: "Playlists",
                        icon: Icons.playlist_play,
                      ),
                      _Stat(
                        value: categories.length,
                        label: "Categories",
                        icon: Icons.category,
                      ),
                      _Stat(
                        value: channelCount,
                        label: "Channels",
                        icon: Icons.tv,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Category list
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.playlist_add, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          const Text(
            "No playlists yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Add your first playlist in settings",
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push("/settings/playlists"),
            icon: const Icon(Icons.add),
            label: const Text("Add Playlist"),
          ),
        ],
      ),
    );
  }
}

/// Channel search results from all playlists
class _ChannelResults extends StatelessWidget {
  const _ChannelResults({required this.channels, required this.hasQuery});

  final List<Channel> channels;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    if (!hasQuery || channels.isEmpty) {
      return Center(
        child: Text(
          hasQuery ? "No channels match your search" : "Type to search channel names in all playlists",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            "${formatChannelCount(channels.length)} found",
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return ChannelTile(channel: channel, subtitle: channel.groupTitle ?? "");
            },
          ),
        ),
      ],
    );
  }
}

class _FavoritesTile extends StatelessWidget {
  const _FavoritesTile({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.amber,
          child: Icon(Icons.star, color: Colors.white),
        ),
        title: const Text(
          "Favorites",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(formatChannelCount(count)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push("/favorites"),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  /// Matches country codes as whole words, so e.g. "music" isn't "us"
  static final _countryPattern = RegExp(r"\b(?:uk|gb|usa?|nl|netherlands)\b");

  final ChannelCategory category;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary,
          child: Icon(_categoryIcon(), color: colorScheme.onPrimary),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(formatChannelCount(category.channels.length)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push("/category-channels", extra: category),
      ),
    );
  }

  IconData _categoryIcon() {
    final name = category.name.toLowerCase();

    if (name.contains("sport")) return Icons.sports_soccer;
    if (name.contains("news")) return Icons.newspaper;
    if (name.contains("movie")) return Icons.movie;
    if (name.contains("series")) return Icons.tv_rounded;
    if (name.contains("kids") || name.contains("cartoon")) {
      return Icons.child_care;
    }
    if (name.contains("music")) return Icons.music_note;
    if (name.contains("documentary")) return Icons.science;
    if (name.contains("entertainment")) return Icons.theaters;
    if (name.contains("religious")) return Icons.church;
    if (_countryPattern.hasMatch(name)) return Icons.flag;

    return Icons.live_tv;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon});

  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              "$value",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}
