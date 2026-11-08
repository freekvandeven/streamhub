import "package:flutter_test/flutter_test.dart";
import "package:streamhub/utils/redact.dart";

void main() {
  test("hides the credentials in a get.php playlist URL", () {
    expect(
      redactUrl("http://provider.example:8080/get.php?username=alice&password=s3cret&type=m3u_plus&output=ts"),
      "http://provider.example:8080/get.php?username=***&password=***&type=m3u_plus&output=ts",
    );
  });

  test("hides user info, unknown query values and fragments", () {
    expect(
      redactUrl("https://alice:s3cret@example.com/list.m3u?token=abc&flag#key"),
      "https://***@example.com/list.m3u?token=***&***#***",
    );
  });

  test("hides the credentials in Xtream Codes stream paths", () {
    expect(redactUrl("http://host:80/live/alice/s3cret/1234.ts"), "http://host:80/live/***/***/1234.ts");
    expect(redactUrl("http://host/movie/alice/s3cret/99.mkv"), "http://host/movie/***/***/99.mkv");
    expect(
      redactUrl("http://host/timeshift/alice/s3cret/60/2026-01-01:10-00/7.ts"),
      "http://host/timeshift/***/***/60/2026-01-01:10-00/7.ts",
    );
    expect(redactUrl("http://host/alice/s3cret/1234"), "http://host/***/***/1234");
  });

  test("leaves URLs without credentials alone", () {
    const url = "https://iptv-org.github.io/iptv/countries/nl.m3u";
    expect(redactUrl(url), url);
    expect(redactUrl("not a url"), "not a url");
  });

  test("hides the credentials of URLs in text", () {
    expect(
      redactUrls("ClientException: Connection closed, uri=http://host/get.php?username=alice&password=s3cret"),
      "ClientException: Connection closed, uri=http://host/get.php?username=***&password=***",
    );
    expect(
      redactUrls('Failed "http://host/live/a/b/1.ts" and http://other/x.m3u'),
      'Failed "http://host/live/***/***/1.ts" and http://other/x.m3u',
    );
  });
}
