import "dart:async";

import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:streamhub/utils/logger.dart";
import "package:video_player/video_player.dart";
import "package:wakelock_plus/wakelock_plus.dart";

/// A stream started with [useVideoStream]: the initialized player (null while
/// loading or after an error), why loading failed, and a way to try again
typedef VideoStream = ({VideoPlayerController? controller, String? error, VoidCallback retry});

/// Creates and initializes a player for [url], and disposes it when the
/// calling widget goes away or retries.
///
/// Set [mixWithOthers] when several streams play at once, so on Android one
/// player taking audio focus doesn't pause the others.
VideoStream useVideoStream(String url, {bool mixWithOthers = false}) {
  // Incremented to recreate the player
  final attempt = useState(0);
  final key = (url, attempt.value);
  // Tagged with the attempt it belongs to, so a stale result is never used
  final outcome = useState<({Object key, VideoPlayerController? controller, String? error})?>(null);

  useEffect(() {
    var disposed = false;
    void complete({VideoPlayerController? controller, String? error}) {
      if (!disposed) outcome.value = (key: key, controller: controller, error: error);
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      // Can't update state while building, so report it right after
      unawaited(Future.microtask(() => complete(error: "Invalid stream URL")));
      return () => disposed = true;
    }

    final controller = VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: mixWithOthers),
    );

    Future<void> initialize() async {
      try {
        await controller.initialize();
        complete(controller: controller);
      } on Object catch (e) {
        // Show any failure, including platforms without a video_player
        // implementation, instead of loading forever
        complete(error: e.toString());
      }
    }

    unawaited(initialize());
    return () {
      disposed = true;
      unawaited(controller.dispose());
    };
  }, [url, attempt.value, mixWithOthers]);

  final current = outcome.value?.key == key ? outcome.value : null;
  return (controller: current?.controller, error: current?.error, retry: () => attempt.value++);
}

/// Keeps the screen on while the calling widget is shown
void useWakelock() {
  useEffect(() {
    unawaited(_setWakelock(enabled: true));
    return () => unawaited(_setWakelock(enabled: false));
  }, const []);
}

Future<void> _setWakelock({required bool enabled}) async {
  try {
    await WakelockPlus.toggle(enable: enabled);
  } on Exception catch (e) {
    // Not available on every platform, nor in tests
    Logger.warning("Couldn't ${enabled ? "enable" : "disable"} the wakelock: $e");
  }
}

/// Allows landscape while the calling widget is shown, then restores the
/// platform default orientations
void useAllowLandscape() {
  useEffect(() {
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]),
    );
    return () => unawaited(SystemChrome.setPreferredOrientations([]));
  }, const []);
}
