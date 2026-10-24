import "package:flutter_test/flutter_test.dart";
import "package:streamhub/models/channel.dart";

void main() {
  test("streamHost hides the path, which may contain credentials", () {
    const channel = Channel(name: "Channel", url: "http://provider.example:8080/live/user/secret/123.ts");
    expect(channel.streamHost, "provider.example");
    expect(const Channel(name: "Channel", url: "not a url").streamHost, isEmpty);
  });
}
