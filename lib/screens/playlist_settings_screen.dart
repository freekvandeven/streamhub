import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/providers/playlists_provider.dart";

class PlaylistSettingsScreen extends HookConsumerWidget {
  const PlaylistSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultUrl = dotenv.env["PLAYLIST_URL"] ?? "";
    final urlController = useTextEditingController(text: defaultUrl);
    final nameController = useTextEditingController();
    final playlistsState = ref.watch(playlistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Playlists"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Add New Playlist",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            hintText: "My Playlist",
                            border: OutlineInputBorder(),
                            labelText: "Playlist Name",
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: urlController,
                          decoration: const InputDecoration(
                            hintText: "http://example.com/playlist.m3u",
                            border: OutlineInputBorder(),
                            labelText: "M3U Playlist URL",
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: playlistsState.isLoading
                              ? null
                              : () async {
                                  final url = urlController.text.trim();
                                  final name = nameController.text.trim();

                                  if (url.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Please enter a URL"),
                                      ),
                                    );
                                    return;
                                  }

                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please enter a playlist name",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  await ref
                                      .read(playlistsProvider.notifier)
                                      .fetchPlaylist(
                                        url: url,
                                        name: name,
                                      );

                                  // Clear input fields after successful add
                                  if (!playlistsState.isLoading &&
                                      playlistsState.error == null) {
                                    urlController.clear();
                                    nameController.clear();
                                  }
                                },
                          icon: playlistsState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(
                            playlistsState.isLoading
                                ? "Loading..."
                                : "Add Playlist",
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (playlistsState.error != null)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              playlistsState.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (playlistsState.playlists.isNotEmpty) ...[
                  const Text(
                    "My Playlists",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: playlistsState.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlistsState.playlists[index];
                        final isActive =
                            playlist.id == playlistsState.activePlaylistId;

                        return Card(
                          color: isActive ? Colors.blue.shade50 : null,
                          child: ListTile(
                            leading: Icon(
                              Icons.playlist_play,
                              color: isActive ? Colors.blue : null,
                            ),
                            title: Text(
                              playlist.name,
                              style: TextStyle(
                                fontWeight: isActive ? FontWeight.bold : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${playlist.channels.length} channels"),
                                Text(
                                  "Updated: ${_formatDateTime(
                                    playlist.lastUpdate,
                                  )}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isActive)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    onPressed: () async {
                                      await ref
                                          .read(playlistsProvider.notifier)
                                          .setActivePlaylist(playlist.id);
                                    },
                                    tooltip: "Set as active",
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () async {
                                    await ref
                                        .read(playlistsProvider.notifier)
                                        .fetchPlaylist(
                                          url: playlist.url,
                                          name: playlist.name,
                                          forceRefresh: true,
                                        );
                                  },
                                  tooltip: "Refresh",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Delete Playlist"),
                                        content: Text(
                                          "Are you sure you want to delete "
                                          "'${playlist.name}'?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text("Delete"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed ?? false) {
                                      await ref
                                          .read(playlistsProvider.notifier)
                                          .removePlaylist(playlist.id);
                                    }
                                  },
                                  tooltip: "Delete",
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else if (!playlistsState.isLoading)
                  const Expanded(
                    child: Center(
                      child: Text(
                        "No playlists yet. Add one above!",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Loading overlay
          if (playlistsState.isLoading)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          "Loading playlist...",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "This may take a moment for large playlists",
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }
}
