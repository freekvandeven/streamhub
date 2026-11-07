import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/providers/channel_search_provider.dart";
import "package:streamhub/providers/favorites_provider.dart";
import "package:streamhub/utils/formatting.dart";
import "package:streamhub/widgets/channel_logo.dart";

/// Lets the user pick a channel: favorites first, or a search through all
/// playlists. Returns null if the picker is dismissed.
Future<Channel?> showChannelPicker(BuildContext context) {
  return showModalBottomSheet<Channel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const FractionallySizedBox(
      heightFactor: 0.9,
      child: _ChannelPicker(),
    ),
  );
}

class _ChannelPicker extends HookConsumerWidget {
  const _ChannelPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = useState("");
    final favorites = ref.watch(favoriteChannelsProvider);
    final searchable = ref.watch(searchableChannelsProvider);
    final results = useMemoized(() => searchChannels(searchable, query.value), [searchable, query.value]);

    final showFavorites = query.value.trim().isEmpty;
    final channels = showFavorites ? favorites : results;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text("Add a channel", style: Theme.of(context).textTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Search all channels...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => query.value = value,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            showFavorites ? "Favorites" : "${formatChannelCount(channels.length)} found",
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Expanded(
          child: channels.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      showFavorites
                          ? "Search for a channel, or star channels to find them here"
                          : "No channels match your search",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return ListTile(
                      leading: ChannelLogo(url: channel.tvgLogo, size: 40),
                      title: Text(channel.name),
                      subtitle: Text(
                        channel.groupTitle ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.of(context).pop(channel),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
