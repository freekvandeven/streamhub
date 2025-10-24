import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "package:streamhub/screens/home_screen.dart";

void main() {
  setUpAll(() async {
    // Initialize dotenv for tests (empty/mocked values)
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: "PLAYLIST_URL=");

    // Initialize Hive with in-memory storage for tests
    Hive.init("test_hive");
    await Hive.openBox<dynamic>("playlists");
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets("App loads home screen with URL input", (
    WidgetTester tester,
  ) async {
    // Build home screen directly for testing
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    // Verify that we're on the home screen with new title
    expect(find.text("StreamHub"), findsOneWidget);
    expect(find.text("Enter Playlist Details"), findsOneWidget);
    expect(find.text("Add Playlist"), findsOneWidget);

    // Verify both input fields exist (name and URL)
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets("Can enter URL in text field", (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    // Find the URL text field specifically by label
    final urlField = find.widgetWithText(TextField, "M3U Playlist URL");
    expect(urlField, findsOneWidget);

    await tester.enterText(urlField, "http://example.com/playlist.m3u");
    await tester.pump();

    // Verify the text was entered
    expect(find.text("http://example.com/playlist.m3u"), findsOneWidget);
  });

  testWidgets("Add Playlist button is present", (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    // Find the add playlist button by text
    final addButton = find.text("Add Playlist");
    expect(addButton, findsOneWidget);
  });
}
