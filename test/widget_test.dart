import "dart:io";
import "dart:typed_data";

// Legacy Material, as still used by packages like chewie
import "package:flutter/material.dart" as legacy;
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:streamhub/main.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/models/playlist.dart";
import "package:streamhub/providers/playlists_provider.dart";
import "package:streamhub/screens/home_screen.dart";
import "package:streamhub/screens/playlist_settings_screen.dart";
import "package:streamhub/screens/settings_screen.dart";
import "package:streamhub/screens/video_player_screen.dart";
import "package:streamhub/services/playlist_storage.dart";

import "helpers/memory_playlist_storage.dart";

final _playlist = Playlist(
  id: "1",
  name: "Test",
  url: "http://example.com/test.m3u",
  channels: const [
    Channel(name: "Sky Sports", url: "http://s/1", groupTitle: "Sports"),
    Channel(name: "ESPN", url: "http://s/2", groupTitle: "Sports"),
    Channel(name: "BBC News", url: "http://s/3", groupTitle: "News"),
  ],
  lastUpdate: DateTime(2025),
);

/// Halfway through downloading a playlist
class _DownloadingNotifier extends PlaylistsNotifier {
  @override
  PlaylistsState build() => const PlaylistsState(
    isLoading: true,
    downloadProgress: DownloadProgress(receivedBytes: 128 << 20, totalBytes: 256 << 20, channels: 4321),
  );
}

/// Runs [child] with playlists kept in memory, optionally with [_playlist]
Widget _scope(Widget child, {bool withPlaylist = false}) {
  return ProviderScope(
    overrides: [
      playlistStorageProvider.overrideWithValue(MemoryPlaylistStorage([if (withPlaylist) _playlist])),
    ],
    child: child,
  );
}

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp("streamhub_widget_");
    Hive.init(hiveDir.path);
  });

  setUp(() async {
    // Favorites are written from the UI, and widget tests can't wait for real
    // file IO, so keep them in memory
    final favorites = await Hive.openBox<dynamic>("favorites", bytes: Uint8List(0));
    await favorites.clear();
  });

  tearDownAll(() async {
    // The in-memory box has nothing on disk to delete
    await Hive.box<dynamic>("favorites").close();
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
  });

  testWidgets("App loads home screen with categories view", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _scope(const MaterialApp(home: HomeScreen())),
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
      _scope(const MaterialApp(home: HomeScreen())),
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
    await tester.pumpWidget(_scope(const MaterialApp(home: HomeScreen()), withPlaylist: true));
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
    await tester.pumpWidget(_scope(const MyApp(), withPlaylist: true));
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

  testWidgets("Adds a channel to favorites", (WidgetTester tester) async {
    await tester.pumpWidget(_scope(const MyApp(), withPlaylist: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Sports"));
    await tester.pumpAndSettle();
    final espn = find.widgetWithText(ListTile, "ESPN");
    await tester.tap(find.descendant(of: espn, matching: find.byTooltip("Add to favorites")));
    await tester.pump();
    expect(find.descendant(of: espn, matching: find.byIcon(Icons.star)), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.widgetWithText(Card, "Favorites"), matching: find.text("1 channel")),
      findsOneWidget,
    );

    await tester.tap(find.text("Favorites"));
    await tester.pumpAndSettle();
    expect(find.text("ESPN"), findsOneWidget);
    expect(find.text("Sky Sports"), findsNothing);
  });

  testWidgets("Searches channels in all categories", (WidgetTester tester) async {
    await tester.pumpWidget(_scope(const MaterialApp(home: HomeScreen()), withPlaylist: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip("Search channel names in all playlists"));
    await tester.pump();
    expect(find.text("Type to search channel names in all playlists"), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, "Search all channels..."), "s");
    await tester.pump();

    // Channels from both categories, names starting with the search first
    final titles = [
      for (final tile in tester.widgetList<ListTile>(find.byType(ListTile))) (tile.title! as Text).data,
    ];
    expect(titles, ["Sky Sports", "ESPN", "BBC News"]);
    expect(find.text("3 channels found"), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, "Search all channels..."), "xyz");
    await tester.pump();
    expect(find.text("No channels match your search"), findsOneWidget);
  });

  testWidgets("Uses Material page routes", (WidgetTester tester) async {
    await tester.pumpWidget(_scope(const MyApp()));
    await tester.pumpAndSettle();

    // go_router only builds Material pages (with their transitions) when it
    // finds a material_ui MaterialApp above it
    final route = ModalRoute.of(tester.element(find.byType(HomeScreen)));
    expect(route, isA<MaterialRouteTransitionMixin<dynamic>>());
  });

  testWidgets("Provides legacy Material theme and localizations", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_scope(const MyApp()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HomeScreen));
    expect(legacy.MaterialLocalizations.of(context), isNotNull);
    expect(
      legacy.Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.primary,
    );
  });

  testWidgets("Shows playlist download progress", (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [playlistsProvider.overrideWith(_DownloadingNotifier.new)],
        child: const MaterialApp(home: PlaylistSettingsScreen()),
      ),
    );

    expect(find.text("Downloading playlist..."), findsOneWidget);
    expect(find.text("128.00 MB of 256.00 MB"), findsOneWidget);
    expect(find.text("4321 channels found"), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.5);
  });

  testWidgets("Shows the app version in settings", (WidgetTester tester) async {
    PackageInfo.setMockInitialValues(
      appName: "StreamHub",
      packageName: "com.streamhub.app",
      version: "1.2.3",
      buildNumber: "4",
      buildSignature: "",
    );
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text("1.2.3 (4)"), findsOneWidget);
  });

  testWidgets("Retries a stream that failed to load", (WidgetTester tester) async {
    // video_player has no platform implementation in tests, so loading fails
    await tester.pumpWidget(
      _scope(
        const MaterialApp(
          home: VideoPlayerScreen(
            channel: Channel(name: "Test", url: "https://example.com/stream.m3u8"),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Failed to Load Stream"), findsOneWidget);

    await tester.tap(find.text("Retry"));
    await tester.pump();
    expect(find.text("Loading stream..."), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text("Failed to Load Stream"), findsOneWidget);
  });
}
