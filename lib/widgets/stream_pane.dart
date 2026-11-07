import "dart:async";

import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:streamhub/hooks/video_hooks.dart";
import "package:streamhub/models/channel.dart";
import "package:video_player/video_player.dart";

/// One stream in the split screen. Only the active stream is heard.
class StreamPane extends HookWidget {
  const StreamPane({
    required this.channel,
    required this.isActive,
    required this.onActivate,
    required this.onRemove,
    required this.onOpen,
    super.key,
  });

  final Channel channel;

  /// Whether this stream's audio plays; the other streams are muted
  final bool isActive;

  /// Makes this the stream that's heard
  final VoidCallback onActivate;

  /// Removes the stream from the split screen
  final VoidCallback onRemove;

  /// Opens the stream in the full player
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    // Mixed, so the streams don't pause each other over audio focus
    final stream = useVideoStream(channel.url, mixWithOthers: true);
    final controller = stream.controller;

    // Set the volume before playing, so a muted stream never blips
    useEffect(() {
      unawaited(controller?.setVolume(isActive ? 1 : 0));
      return null;
    }, [controller, isActive]);
    useEffect(() {
      unawaited(controller?.play());
      return null;
    }, [controller]);

    final Widget video;
    if (stream.error case final error?) {
      video = _PaneError(message: error, onRetry: stream.retry);
    } else if (controller == null) {
      video = const CircularProgressIndicator(color: Colors.white);
    } else {
      video = ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) => Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(aspectRatio: value.aspectRatio, child: VideoPlayer(controller)),
            if (value.isBuffering) const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onActivate,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: Center(child: video),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _PaneBar(
              channel: channel,
              isActive: isActive,
              onActivate: onActivate,
              onRemove: onRemove,
              onOpen: onOpen,
            ),
          ),
          // Highlights the stream that's heard
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive ? Theme.of(context).colorScheme.primary : Colors.white24,
                  width: isActive ? 3 : 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaneBar extends StatelessWidget {
  const _PaneBar({
    required this.channel,
    required this.isActive,
    required this.onActivate,
    required this.onRemove,
    required this.onOpen,
  });

  final Channel channel;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: IconButtonTheme(
        data: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
            iconSize: 20,
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(isActive ? Icons.volume_up : Icons.volume_off),
              tooltip: isActive ? "Playing this stream's audio" : "Play this stream's audio",
              onPressed: onActivate,
            ),
            Expanded(
              child: Text(
                channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_full),
              tooltip: "Open in full player",
              onPressed: onOpen,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: "Remove from split screen",
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaneError extends StatelessWidget {
  const _PaneError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Scale down to fit small panes in the 2x2 grid
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              const Text(
                "Couldn't load stream",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
