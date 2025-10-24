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

  testWidgets("App loads home screen with categories view", (
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

    // Verify settings button exists
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Verify search field exists
    expect(
      find.widgetWithText(TextField, "Search categories..."),
      findsOneWidget,
    );
  });

  testWidgets(
    "Shows empty state when no playlists",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state message
      expect(find.text("No playlists yet"), findsOneWidget);
      expect(
        find.text("Add your first playlist in settings"),
        findsOneWidget,
      );
    },
  );

  testWidgets("Can search categories", (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    // Find the search field
    final searchField = find.widgetWithText(TextField, "Search categories...");
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, "sports");
    await tester.pump();

    // Verify the text was entered
    expect(find.text("sports"), findsOneWidget);
  });
}
