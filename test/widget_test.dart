import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "package:iptv_app/main.dart";

void main() {
  setUpAll(() async {
    // Initialize dotenv for tests (empty/mocked values)
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: "IPTV_PLAYLIST_URL=");
  });

  testWidgets("App loads home screen with URL input", (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that we're on the home screen
    expect(find.text("IPTV Playlist Loader"), findsOneWidget);
    expect(find.text("Enter Playlist URL"), findsOneWidget);
    expect(find.text("Load Playlist"), findsOneWidget);

    // Verify the URL input field exists
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets("Can enter URL in text field", (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Find the text field and enter a URL
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, "http://example.com/playlist.m3u");
    await tester.pump();

    // Verify the text was entered
    expect(find.text("http://example.com/playlist.m3u"), findsOneWidget);
  });

  testWidgets("Load Playlist button is present", (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Find the load playlist button by text
    final loadButton = find.text("Load Playlist");
    expect(loadButton, findsOneWidget);
  });
}
