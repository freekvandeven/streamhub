import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/providers/playlist_provider.dart";

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultUrl = dotenv.env["PLAYLIST_URL"] ?? "";
    final urlController = useTextEditingController(text: defaultUrl);
    final playlistState = ref.watch(playlistProvider);

    // Load from cache on first build
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(playlistProvider.notifier).loadFromCache();
      });
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Playlist Loader"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
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
                      "Enter Playlist URL",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        hintText:
                            "http://example.com/playlist.m3u",
                        border: OutlineInputBorder(),
                        labelText: "M3U Playlist URL",
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: playlistState.isLoading
                          ? null
                          : () async {
                              final url = urlController.text.trim();
                              if (url.isNotEmpty) {
                                await ref
                                    .read(playlistProvider.notifier)
                                    .fetchPlaylist(url);
                              }
                            },
                      icon: playlistState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(
                        playlistState.isLoading
                            ? "Loading..."
                            : "Load Playlist",
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
            if (playlistState.error != null)
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
                          playlistState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (playlistState.channels.isNotEmpty) ...[
              Card(
                color: playlistState.isFromCache
                    ? Colors.blue.shade50
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${playlistState.channels.length} channels",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      playlistState.isFromCache
                                          ? Icons.storage
                                          : Icons.cloud_download,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      playlistState.isFromCache
                                          ? "From cache"
                                          : "Fresh from URL",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                if (playlistState.lastUpdateTime != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Updated: ${_formatDateTime(
                                      playlistState.lastUpdateTime!,
                                    )}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (playlistState.isFromCache)
                            IconButton(
                              onPressed: () async {
                                final url = urlController.text.trim();
                                if (url.isNotEmpty) {
                                  await ref
                                      .read(playlistProvider.notifier)
                                      .fetchPlaylist(url, forceRefresh: true);
                                }
                              },
                              icon: const Icon(Icons.refresh),
                              tooltip: "Refresh from URL",
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go("/channels"),
                          icon: const Icon(Icons.list),
                          label: const Text("View Channels"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
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
