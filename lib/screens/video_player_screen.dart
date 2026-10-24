import "dart:async";

import "package:chewie/chewie.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/widgets/channel_logo.dart";
import "package:video_player/video_player.dart";

/// Video player screen for live channels, movies, and TV series
class VideoPlayerScreen extends HookWidget {
  const VideoPlayerScreen({
    required this.channel,
    super.key,
  });

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final videoPlayerController = useMemoized(
      () => VideoPlayerController.networkUrl(Uri.parse(channel.url)),
      [channel.url],
    );

    final chewieController = useState<ChewieController?>(null);
    final errorMessage = useState<String?>(null);

    // Capture theme colors before async operations
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Initialize video player
    useEffect(() {
      var disposed = false;
      ChewieController? chewie;

      Future<void> initializePlayer() async {
        try {
          await videoPlayerController.initialize();
          // The screen may have been closed while the stream was loading
          if (disposed) return;

          chewie = ChewieController(
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
            ),
          );
          chewieController.value = chewie;
        } on Exception catch (e) {
          if (!disposed) errorMessage.value = e.toString();
        }
      }

      unawaited(initializePlayer());

      // Cleanup
      return () {
        disposed = true;
        chewie?.dispose();
        unawaited(videoPlayerController.dispose());
      };
    }, [videoPlayerController]);

    // Allow landscape while the player is open, then restore the defaults
    useEffect(() {
      unawaited(
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.portraitUp,
        ]),
      );

      return () => unawaited(SystemChrome.setPreferredOrientations([]));
    }, []);

    final Widget body;
    if (errorMessage.value case final message?) {
      body = _PlaybackError(
        title: "Failed to Load Stream",
        message: message,
        details: "Server: ${channel.streamHost}",
      );
    } else if (chewieController.value case final controller?) {
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
      ),
      body: Center(child: body),
    );
  }
}

class _PlaybackError extends StatelessWidget {
  const _PlaybackError({
    required this.title,
    required this.message,
    this.details,
  });

  final String title;
  final String message;
  final String? details;

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
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }
}
