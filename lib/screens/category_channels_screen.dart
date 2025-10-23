import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/models/channel.dart";

/// Screen showing channels within a specific category
class CategoryChannelsScreen extends HookConsumerWidget {
  const CategoryChannelsScreen({
    required this.categoryName,
    required this.channels,
    super.key,
  });

  final String categoryName;
  final List<Channel> channels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState("");
    final sortByName = useState(true);

    // Filter and sort channels
    final displayChannels = useMemoized(() {
      var filtered = channels;

      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        filtered = filtered.where((channel) {
          return channel.name.toLowerCase().contains(query);
        }).toList();
      }

      // Sort channels
      final sorted = List<Channel>.from(filtered);
      if (sortByName.value) {
        sorted.sort((a, b) => a.name.compareTo(b.name));
      }

      return sorted;
    }, [channels, searchQuery.value, sortByName.value]);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(categoryName),
            Text(
              "${displayChannels.length} channels",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go("/categories"),
        ),
        actions: [
          IconButton(
            icon: Icon(sortByName.value ? Icons.sort_by_alpha : Icons.sort),
            tooltip: sortByName.value ? "Sort by name" : "Original order",
            onPressed: () => sortByName.value = !sortByName.value,
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
                hintText: "Search channels...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => searchQuery.value = value,
            ),
          ),

          // Channel list
          Expanded(
            child: displayChannels.isEmpty
                ? Center(
                    child: Text(
                      searchQuery.value.isEmpty
                          ? "No channels in this category"
                          : "No channels match your search",
                    ),
                  )
                : ListView.builder(
                    itemCount: displayChannels.length,
                    itemBuilder: (context, index) {
                      final channel = displayChannels[index];

                      return ListTile(
                        leading: channel.tvgLogo != null
                            ? Image.network(
                                channel.tvgLogo!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.tv);
                                },
                              )
                            : const Icon(Icons.tv),
                        title: Text(channel.name),
                        subtitle: Text(
                          channel.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: const Icon(Icons.play_circle_outline),
                        onTap: () {
                          // TODO(video-playback): Implement video playback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Playing: ${channel.name}"),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
