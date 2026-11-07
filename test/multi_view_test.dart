import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/models/playlist.dart";
import "package:streamhub/screens/multi_view_screen.dart";
import "package:streamhub/services/playlist_storage.dart";
import "package:streamhub/widgets/stream_pane.dart";

// video_player has no platform implementation in tests, so the panes show an
// error, which is enough to check the layout and behavior
const _one = Channel(name: "Channel One", url: "https://s/1.m3u8", groupTitle: "News");
const _two = Channel(name: "Channel Two", url: "https://s/2.m3u8", groupTitle: "Sports");
const _three = Channel(name: "Channel Three", url: "https://s/3.m3u8", groupTitle: "Kids");

Future<void> _pumpMultiView(WidgetTester tester, List<Channel> channels, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: MultiViewScreen(initialChannels: channels)),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _pane(String name) => find.widgetWithText(StreamPane, name);

Finder _inPane(String name, Finder finder) => find.descendant(of: _pane(name), matching: finder);

void main() {
  setUp(() async {
    // In memory, so storage writes complete within widget tests
    for (final name in ["playlists", "favorites"]) {
      final box = await Hive.openBox<dynamic>(name, bytes: Uint8List(0));
      await box.clear();
    }
  });

  testWidgets("shows two streams side by side on wide screens", (WidgetTester tester) async {
    await _pumpMultiView(tester, [_one, _two], size: const Size(1200, 700));

    final one = tester.getTopLeft(find.text("Channel One"));
    final two = tester.getTopLeft(find.text("Channel Two"));
    expect(two.dy, one.dy);
    expect(two.dx, greaterThan(one.dx));
  });

  testWidgets("stacks two streams on narrow screens", (WidgetTester tester) async {
    await _pumpMultiView(tester, [_one, _two], size: const Size(400, 800));

    final one = tester.getTopLeft(find.text("Channel One"));
    final two = tester.getTopLeft(find.text("Channel Two"));
    expect(two.dx, one.dx);
    expect(two.dy, greaterThan(one.dy));
  });

  testWidgets("shows more than two streams in a 2x2 grid", (WidgetTester tester) async {
    await _pumpMultiView(tester, [_one, _two, _three], size: const Size(1200, 700));

    final one = tester.getTopLeft(find.text("Channel One"));
    final two = tester.getTopLeft(find.text("Channel Two"));
    final three = tester.getTopLeft(find.text("Channel Three"));
    expect(two.dy, one.dy);
    expect(three.dx, one.dx);
    expect(three.dy, greaterThan(one.dy));
    // The fourth cell offers another stream
    expect(find.text("Add channel"), findsOneWidget);
  });

  testWidgets("plays the audio of the stream that was tapped", (WidgetTester tester) async {
    await _pumpMultiView(tester, [_one, _two], size: const Size(1200, 700));
    expect(_inPane("Channel One", find.byIcon(Icons.volume_up)), findsOneWidget);
    expect(_inPane("Channel Two", find.byIcon(Icons.volume_off)), findsOneWidget);

    await tester.tap(_inPane("Channel Two", find.byTooltip("Play this stream's audio")));
    await tester.pump();

    expect(_inPane("Channel One", find.byIcon(Icons.volume_off)), findsOneWidget);
    expect(_inPane("Channel Two", find.byIcon(Icons.volume_up)), findsOneWidget);
  });

  testWidgets("adds a channel from the picker and removes streams", (WidgetTester tester) async {
    await tester.runAsync(
      () => PlaylistStorage.savePlaylist(
        Playlist(
          id: "1",
          name: "Test",
          url: "http://example.com/test.m3u",
          channels: const [_one, _two],
          lastUpdate: DateTime(2025),
        ),
      ),
    );
    await _pumpMultiView(tester, [_one], size: const Size(1200, 700));

    await tester.tap(find.text("Add channel"));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, "Search all channels..."), "two");
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, "Channel Two"));
    await tester.pumpAndSettle();

    expect(_pane("Channel Two"), findsOneWidget);
    expect(find.text("Add channel"), findsNothing);

    await tester.tap(_inPane("Channel One", find.byTooltip("Remove from split screen")));
    await tester.pumpAndSettle();

    expect(_pane("Channel One"), findsNothing);
    expect(find.text("Add channel"), findsOneWidget);
    // The remaining stream is heard now
    expect(_inPane("Channel Two", find.byIcon(Icons.volume_up)), findsOneWidget);
  });
}
