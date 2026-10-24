import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:streamhub/services/channel_categorizer.dart";
import "package:streamhub/services/m3u_parser.dart";

void main() {
  test("sample playlist parses and categorizes", () {
    final content = File("samples/test_playlist.m3u").readAsStringSync();
    final channels = ChannelCategorizer.categorize(M3uParser.parse(content));

    expect(channels, hasLength(7));
    expect(channels.every((c) => c.url.startsWith("https://")), isTrue);
    expect(
      {for (final c in channels) c.groupTitle},
      {"Live Test Streams", "Blender Open Movies", "Movies"},
    );
  });
}
