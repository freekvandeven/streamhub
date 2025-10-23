import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/providers/playlist_provider.dart";

/// Screen showing categories/groups of channels
class CategoriesScreen extends HookConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistState = ref.watch(playlistProvider);
    final searchQuery = useState("");

    // Group channels by category
    final categoryData = useMemoized(() {
      final groups = <String, List<Channel>>{};
      for (final channel in playlistState.channels) {
        final group = channel.groupTitle ?? "Uncategorized";
        groups.putIfAbsent(group, () => []);
        groups[group]!.add(channel);
      }

      // Convert to list and sort by channel count
      final categoryList =
          groups.entries
              .map(
                (e) => <String, Object>{
                  "name": e.key,
                  "count": e.value.length,
                  "channels": e.value,
                },
              )
              .toList()
            ..sort(
              (a, b) => (b["count"]! as int).compareTo(a["count"]! as int),
            );

      return categoryList;
    }, [playlistState.channels]);

    // Filter categories based on search
    final filteredCategories = useMemoized(() {
      if (searchQuery.value.isEmpty) {
        return categoryData;
      }
      final query = searchQuery.value.toLowerCase();
      return categoryData.where((cat) {
        final name = (cat["name"]! as String).toLowerCase();
        return name.contains(query);
      }).toList();
    }, [categoryData, searchQuery.value]);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go("/"),
        ),
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
          if (playlistState.channels.isNotEmpty)
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
                      _buildStat(
                        context,
                        "${categoryData.length}",
                        "Categories",
                        Icons.category,
                      ),
                      _buildStat(
                        context,
                        "${playlistState.channels.length}",
                        "Channels",
                        Icons.tv,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Category list
          Expanded(
            child: playlistState.channels.isEmpty
                ? const Center(child: Text("No categories available"))
                : ListView.builder(
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      final name = category["name"]! as String;
                      final count = category["count"]! as int;
                      final channels = category["channels"]! as List<Channel>;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            child: Icon(
                              _getCategoryIcon(name),
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text("$count channels"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Navigate to channels in this category
                            context.go(
                              "/category-channels",
                              extra: {
                                "categoryName": name,
                                "channels": channels,
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

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

    // Country-specific
    if (name.contains("uk") || name.contains("gb")) return Icons.flag;
    if (name.contains("us") || name.contains("usa")) return Icons.flag;
    if (name.contains("nl") || name.contains("netherlands")) return Icons.flag;

    return Icons.live_tv;
  }
}
