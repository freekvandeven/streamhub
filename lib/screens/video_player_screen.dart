import "package:chewie/chewie.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/models/channel.dart";
import "package:video_player/video_player.dart";

/// Video player screen for live channels, movies, and TV series
class VideoPlayerScreen extends HookConsumerWidget {
  const VideoPlayerScreen({
    required this.channel,
    super.key,
  });

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoPlayerController = useMemoized(
      () => VideoPlayerController.networkUrl(
        Uri.parse(channel.url),
      ),
      [channel.url],
    );

    final chewieController = useState<ChewieController?>(null);
    final isInitialized = useState(false);
    final hasError = useState(false);
    final errorMessage = useState("");

    // Capture theme colors before async operations
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bufferedColor = primaryColor.withValues(alpha: 0.3);

    // Initialize video player
    useEffect(() {
      Future<void> initializePlayer() async {
        try {
          await videoPlayerController.initialize();

          chewieController.value = ChewieController(
            videoPlayerController: videoPlayerController,
            autoPlay: true,
            looping: false,
            allowFullScreen: true,
            allowMuting: true,
            showControls: true,
            materialProgressColors: ChewieProgressColors(
              playedColor: primaryColor,
              handleColor: primaryColor,
              backgroundColor: Colors.grey,
              bufferedColor: bufferedColor,
            ),
            placeholder: ColoredBox(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (channel.tvgLogo != null)
                      Image.network(
                        channel.tvgLogo!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.tv,
                            size: 120,
                            color: Colors.white,
                          );
                        },
                      )
                    else
                      const Icon(
                        Icons.tv,
                        size: 120,
                        color: Colors.white,
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
            errorBuilder: (context, errorMessage) {
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
                      const Text(
                        "Playback Error",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
            },
          );

          isInitialized.value = true;
        } on Exception catch (e) {
          hasError.value = true;
          errorMessage.value = e.toString();
        }
      }

      // ignore: discarded_futures
      initializePlayer();

      // Cleanup
      return () {
        // ignore: discarded_futures
        chewieController.value?.dispose();
        // ignore: discarded_futures
        videoPlayerController.dispose();
      };
    }, [channel.url]);

    // Enable landscape mode for video playback
    useEffect(() {
      // ignore: discarded_futures
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]);

      return () {
        // ignore: discarded_futures
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      };
    }, []);

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
            if (channel.groupTitle != null)
              Text(
                channel.groupTitle!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: hasError.value
            ? ColoredBox(
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
                      const Text(
                        "Failed to Load Stream",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage.value,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "URL: ${channel.url}",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Go Back"),
                      ),
                    ],
                  ),
                ),
              )
            : !isInitialized.value
            ? const Column(
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
              )
            : chewieController.value != null
            ? Chewie(controller: chewieController.value!)
            : const SizedBox.shrink(),
      ),
    );
  }
}
