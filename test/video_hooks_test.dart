import "package:flutter/widgets.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_test/flutter_test.dart";
import "package:streamhub/hooks/video_hooks.dart";
import "package:streamhub/utils/wakelock.dart";
import "package:video_player/video_player.dart";

Widget _watching(VideoStream stream) {
  return HookBuilder(
    builder: (context) {
      useWakelockWhileWatching(stream);
      return const SizedBox();
    },
  );
}

void main() {
  void retry() {}

  testWidgets("keeps the screen on while loading, until the widget goes away", (WidgetTester tester) async {
    await tester.pumpWidget(_watching((controller: null, error: null, retry: retry)));
    expect(Wakelock.holders, 1);

    await tester.pumpWidget(const SizedBox());
    expect(Wakelock.holders, 0);
  });

  testWidgets("lets the screen turn off when loading failed", (WidgetTester tester) async {
    await tester.pumpWidget(_watching((controller: null, error: "Failed", retry: retry)));

    expect(Wakelock.holders, 0);
  });

  testWidgets("keeps the screen on while playing or buffering only", (WidgetTester tester) async {
    // Never initialized, the test sets its state directly
    final player = VideoPlayerController.networkUrl(Uri.parse("https://example.com/stream.m3u8"));
    addTearDown(player.dispose);
    await tester.pumpWidget(_watching((controller: player, error: null, retry: retry)));
    expect(Wakelock.holders, 0, reason: "not started yet");

    Future<void> update(VideoPlayerValue value) async {
      player.value = value;
      await tester.pump();
    }

    await update(player.value.copyWith(isPlaying: true));
    expect(Wakelock.holders, 1, reason: "playing");

    // Android reports a stream that rebuffers as not playing
    await update(player.value.copyWith(isPlaying: false, isBuffering: true));
    expect(Wakelock.holders, 1, reason: "buffering");

    await update(player.value.copyWith(isBuffering: false));
    expect(Wakelock.holders, 0, reason: "paused");

    await update(player.value.copyWith(isPlaying: true, errorDescription: "Stream lost"));
    expect(Wakelock.holders, 0, reason: "failed");
  });
}
