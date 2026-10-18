import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/providers/playlists_provider.dart";

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsState = ref.watch(playlistsProvider);
    final playlists = playlistsState.playlists;
    final searchQuery = useState("");

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

    final Widget content;
    if (playlistsState.isLoading && channelCount == 0) {
      content = const Center(child: CircularProgressIndicator());
    } else if (channelCount == 0) {
      content = const _EmptyState();
    } else {
      content = ListView.builder(
        itemCount: filteredCategories.length,
        itemBuilder: (context, index) => _CategoryTile(category: filteredCategories[index]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("StreamHub"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
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
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search categories...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => searchQuery.value = value,
            ),
          ),

          // Summary stats
          if (channelCount > 0)
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
        subtitle: Text("${category.channels.length} channels"),
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
