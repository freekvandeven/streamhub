import "package:flutter_test/flutter_test.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/providers/channel_search_provider.dart";

void main() {
  final channels = [
    for (final name in ["Sky Sports", "ESPN", "BBC News", "SPORT 1"])
      (channel: Channel(name: name, url: "http://s/$name"), name: name.toLowerCase()),
  ];

  List<String> search(String query) => [for (final c in searchChannels(channels, query)) c.name];

  test("matches names ignoring case, names starting with the query first", () {
    expect(search("sport"), ["SPORT 1", "Sky Sports"]);
    expect(search("S"), ["Sky Sports", "SPORT 1", "ESPN", "BBC News"]);
  });

  test("returns nothing for an empty or unmatched query", () {
    expect(search("  "), isEmpty);
    expect(search("xyz"), isEmpty);
  });
}
