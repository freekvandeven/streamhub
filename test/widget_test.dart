import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/main.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/models/playlist.dart";
import "package:streamhub/screens/home_screen.dart";
import "package:streamhub/services/playlist_storage.dart";

Future<void> _savePlaylist() {
  return PlaylistStorage.savePlaylist(
    Playlist(
      id: "1",
      name: "Test",
      url: "http://example.com/test.m3u",
      channels: const [
        Channel(name: "Sky Sports", url: "http://s/1", groupTitle: "Sports"),
        Channel(name: "ESPN", url: "http://s/2", groupTitle: "Sports"),
        Channel(name: "BBC News", url: "http://s/3", groupTitle: "News"),
      ],
      lastUpdate: DateTime(2025),
    ),
  );
}

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    dotenv.loadFromString(envString: "PLAYLIST_URL=");
    hiveDir = await Directory.systemTemp.createTemp("streamhub_widget_");
    Hive.init(hiveDir.path);
  });

  setUp(() async {
    final box = await Hive.openBox<dynamic>("playlists");
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
  });

  testWidgets("App loads home screen with categories view", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text("StreamHub"), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(
      find.widgetWithText(TextField, "Search categories..."),
      findsOneWidget,
    );
  });

  testWidgets("Shows empty state when no playlists", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("No playlists yet"), findsOneWidget);
    expect(
      find.text("Add your first playlist in settings"),
      findsOneWidget,
    );
  });

  testWidgets("Shows saved categories and filters them", (
    WidgetTester tester,
  ) async {
    await tester.runAsync(_savePlaylist);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Sports"), findsOneWidget);
    expect(find.text("2 channels"), findsOneWidget);
    expect(find.text("News"), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, "Search categories..."),
      "spo",
    );
    await tester.pump();

    expect(find.text("Sports"), findsOneWidget);
    expect(find.text("News"), findsNothing);
  });

  testWidgets("Opens a category and navigates back to home", (
    WidgetTester tester,
  ) async {
    await tester.runAsync(_savePlaylist);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Sports"));
    await tester.pumpAndSettle();

    expect(find.text("ESPN"), findsOneWidget);
    expect(find.text("Sky Sports"), findsOneWidget);
    expect(find.text("BBC News"), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text("Search categories..."), findsOneWidget);
  });
}
