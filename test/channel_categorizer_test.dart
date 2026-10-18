import "package:channel_categorizer/channel_categorizer.dart";
import "package:flutter_test/flutter_test.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/services/channel_categorizer.dart";

void main() {
  group("DefaultChannelCategorizer", () {
    const categorizer = DefaultChannelCategorizer();

    String categorize(
      String name, {
      String url = "http://stream/live/123",
      String? groupTitle,
    }) {
      return categorizer.categorizeChannel(name: name, url: url, groupTitle: groupTitle).categoryPath;
    }

    test("keeps an existing group title", () {
      expect(categorize("Anything", groupTitle: "My Group"), "My Group");
      expect(
        categorize("Sky Sports", groupTitle: "Uncategorized"),
        "Live TV > Sports",
      );
    });

    test("treats HLS and MPEG-TS streams as live TV", () {
      expect(categorize("Some Channel", url: "http://x/1.m3u8"), "Live TV");
      expect(
        categorize("Sky Sports 1", url: "http://x/1.ts"),
        "Live TV > Sports",
      );
    });

    test("detects movies", () {
      expect(categorize("Some Film", url: "http://x/1.mp4"), "Movies");
      expect(
        categorize("Big Action (2010)", url: "http://x/1.mkv?token=a"),
        "Movies > Action & Adventure",
      );
      expect(categorize("[VOD] Something"), "Movies");
    });

    test("detects series", () {
      expect(categorize("Show S01E02"), "Series");
      expect(categorize("Show Season 2 drama"), "Series > Drama");
      expect(categorize("Show Ep 3", url: "http://x/1.mkv"), "Series");
      expect(categorize("Show Pt.2", url: "http://x/1.mkv"), "Series");
    });

    test("doesn't mistake words containing 'ep' or 'pt' for episodes", () {
      expect(categorize("Deep Sleep", url: "http://x/1.mp4"), "Movies");
      expect(categorize("Egypt Today", url: "http://x/1.mp4"), "Movies");
    });

    test("detects countries", () {
      expect(categorize("UK: BBC One"), "Live TV > UK");
      expect(categorize("[NL] NPO 1"), "Live TV > Netherlands");
      expect(categorize("USA ESPN"), "Live TV > USA");
      expect(
        categorize("|DE| Sport 1"),
        "Live TV > Sports > Germany Sports",
      );
      expect(categorize("BBC News (UK)"), "Live TV > News > UK News");
    });

    test("doesn't read ordinary leading words as country codes", () {
      expect(categorize("In The Night Garden"), "Live TV");
      expect(categorize("No Limits Music"), "Live TV > Music");
    });
  });

  group("ChannelCategorizer", () {
    test("replaces the group title with the category path", () {
      final channels = ChannelCategorizer.categorize(const [
        Channel(
          name: "ESPN",
          url: "http://stream/1",
          tvgId: "espn",
          tvgName: "ESPN",
          tvgLogo: "http://logo",
        ),
      ]);

      final channel = channels.single;
      expect(channel.groupTitle, "Live TV > Sports");
      expect(channel.name, "ESPN");
      expect(channel.url, "http://stream/1");
      expect(channel.tvgId, "espn");
      expect(channel.tvgName, "ESPN");
      expect(channel.tvgLogo, "http://logo");
    });
  });
}
