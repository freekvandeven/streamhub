import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/playlist_provider.dart';

class ChannelsScreen extends HookConsumerWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistState = ref.watch(playlistProvider);
    final searchQuery = useState('');

    // Filter channels based on search query
    final filteredChannels = useMemoized(() {
      if (searchQuery.value.isEmpty) {
        return playlistState.channels;
      }
      return playlistState.channels.where((channel) {
        final query = searchQuery.value.toLowerCase();
        return channel.name.toLowerCase().contains(query) ||
            (channel.groupTitle?.toLowerCase().contains(query) ?? false);
      }).toList();
    }, [playlistState.channels, searchQuery.value]);

    // Group channels by category
    final groupedChannels = useMemoized(() {
      final Map<String, List<dynamic>> groups = {};
      for (final channel in filteredChannels) {
        final group = channel.groupTitle ?? 'Uncategorized';
        groups.putIfAbsent(group, () => []);
        groups[group]!.add(channel);
      }
      return groups;
    }, [filteredChannels]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search channels...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => searchQuery.value = value,
            ),
          ),
          Expanded(
            child: playlistState.channels.isEmpty
                ? const Center(child: Text('No channels loaded'))
                : ListView.builder(
                    itemCount: groupedChannels.length,
                    itemBuilder: (context, index) {
                      final groupName = groupedChannels.keys.elementAt(index);
                      final channels = groupedChannels[groupName]!;

                      return ExpansionTile(
                        title: Text(
                          groupName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text('${channels.length} channels'),
                        initiallyExpanded: groupedChannels.length <= 3,
                        children: channels.map((channel) {
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
                              // TODO: Implement video playback
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Playing: ${channel.name}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
