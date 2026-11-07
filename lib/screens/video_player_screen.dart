import "package:chewie/chewie.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:streamhub/hooks/video_hooks.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/providers/favorites_provider.dart";
import "package:streamhub/widgets/channel_logo.dart";
import "package:streamhub/widgets/channel_tile.dart";

/// Video player screen for live channels, movies, and TV series
class VideoPlayerScreen extends HookConsumerWidget {
  const VideoPlayerScreen({
    required this.channel,
    super.key,
  });

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesProvider.select((favorites) => favorites.contains(channel.favoriteKey)),
    );

    final stream = useVideoStream(channel.url);
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Chewie adds the controls around the player once it's ready
    final chewieController = useMemoized(() {
      final videoPlayerController = stream.controller;
      if (videoPlayerController == null) return null;

      return ChewieController(
        videoPlayerController: videoPlayerController,
        autoPlay: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: primaryColor,
          handleColor: primaryColor,
          backgroundColor: Colors.grey,
          bufferedColor: primaryColor.withValues(alpha: 0.3),
        ),
        placeholder: ColoredBox(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChannelLogo(
                  url: channel.tvgLogo,
                  size: 120,
                  fallbackColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  channel.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) => _PlaybackError(
          title: "Playback Error",
          message: errorMessage,
          onRetry: stream.retry,
        ),
      );
    }, [stream.controller]);
    useEffect(() => chewieController?.dispose, [chewieController]);

    useAllowLandscape();

    final Widget body;
    if (stream.error case final message?) {
      body = _PlaybackError(
        title: "Failed to Load Stream",
        message: message,
        details: "Server: ${channel.streamHost}",
        onRetry: stream.retry,
      );
    } else if (chewieController case final controller?) {
      body = Chewie(controller: controller);
    } else {
      body = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            "Loading stream...",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              channel.name,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            if (channel.groupTitle case final groupTitle?)
              Text(
                groupTitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          FavoriteButton(channel: channel, isFavorite: isFavorite, color: Colors.white),
        ],
      ),
      body: Center(child: body),
    );
  }
}

class _PlaybackError extends StatelessWidget {
  const _PlaybackError({
    required this.title,
    required this.message,
    required this.onRetry,
    this.details,
  });

  final String title;
  final String message;
  final String? details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (details case final details?) ...[
              const SizedBox(height: 8),
              Text(
                details,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Go Back"),
                ),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
