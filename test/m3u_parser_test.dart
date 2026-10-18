import "package:flutter_test/flutter_test.dart";
import "package:streamhub/services/m3u_parser.dart";

void main() {
  group("M3uParser", () {
    test("parses channels with attributes", () {
      final channels = M3uParser.parse(
        "#EXTM3U\n"
        '#EXTINF:-1 tvg-id="bbc1.uk" tvg-name="BBC One" '
        'tvg-logo="http://logo/bbc1.png" group-title="UK",BBC One HD\n'
        "http://stream/bbc1.m3u8\n"
        "#EXTINF:-1,Plain Channel\n"
        "http://stream/plain.ts\n",
      );

      expect(channels, hasLength(2));
      expect(channels[0].name, "BBC One HD");
      expect(channels[0].url, "http://stream/bbc1.m3u8");
      expect(channels[0].tvgId, "bbc1.uk");
      expect(channels[0].tvgName, "BBC One");
      expect(channels[0].tvgLogo, "http://logo/bbc1.png");
      expect(channels[0].groupTitle, "UK");
      expect(channels[1].name, "Plain Channel");
      expect(channels[1].groupTitle, isNull);
    });

    test("keeps commas in channel names and attribute values", () {
      final channels = M3uParser.parse(
        '#EXTINF:-1 group-title="News, Weather",News, Sport & Weather\n'
        "http://stream/1\n",
      );

      expect(channels.single.name, "News, Sport & Weather");
      expect(channels.single.groupTitle, "News, Weather");
    });

    test("handles CRLF line endings", () {
      final channels = M3uParser.parse(
        "#EXTM3U\r\n#EXTINF:-1,Channel\r\nhttp://stream/1\r\n",
      );

      expect(channels.single.name, "Channel");
      expect(channels.single.url, "http://stream/1");
    });

    test("falls back to tvg-name when the title is missing", () {
      final channels = M3uParser.parse(
        '#EXTINF:-1 tvg-name="Fallback",\n'
        "http://stream/1\n",
      );

      expect(channels.single.name, "Fallback");
    });

    test("ignores other directives and URLs without metadata", () {
      final channels = M3uParser.parse(
        "#EXTM3U\n"
        "http://stream/orphan\n"
        "#EXTINF:-1,Channel\n"
        "#EXTVLCOPT:http-user-agent=Test\n"
        "http://stream/1\n",
      );

      expect(channels.single.url, "http://stream/1");
    });
  });
}
