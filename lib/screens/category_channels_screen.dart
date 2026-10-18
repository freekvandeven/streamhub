import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/widgets/channel_logo.dart";

/// Screen showing channels within a specific category
class CategoryChannelsScreen extends HookWidget {
  const CategoryChannelsScreen({
    required this.category,
    super.key,
  });

  final ChannelCategory category;

  @override
  Widget build(BuildContext context) {
    final searchQuery = useState("");
    final sortByName = useState(true);

    // Filter and sort channels
    final displayChannels = useMemoized(() {
      final query = searchQuery.value.trim().toLowerCase();
      final channels = [
        for (final channel in category.channels)
          if (channel.name.toLowerCase().contains(query)) channel,
      ];

      if (sortByName.value) {
        channels.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      }

      return channels;
    }, [category, searchQuery.value, sortByName.value]);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.name),
            Text(
              "${displayChannels.length} channels",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                        leading: ChannelLogo(url: channel.tvgLogo, size: 48),
                        title: Text(channel.name),
                        subtitle: Text(
                          channel.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.play_circle_outline),
                        onTap: () =>
                            context.push("/video-player", extra: channel),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
