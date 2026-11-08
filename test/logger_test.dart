import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:streamhub/utils/logger.dart";

void main() {
  setUp(() {
    Logger.clear();
    // Messages are also printed in debug builds, like tests
    final print = debugPrint;
    debugPrint = (message, {wrapWidth}) {};
    addTearDown(() => debugPrint = print);
  });

  test("keeps messages with credentials hidden", () {
    Logger.network("GET http://host/get.php?username=alice&password=s3cret");
    Logger.error("Failed", StackTrace.fromString("#0 main"));

    final [request, failure] = Logger.entries;
    expect(request.level, LogLevel.network);
    expect(request.message, "GET http://host/get.php?username=***&password=***");
    expect(failure.message, "Failed\n#0 main");
    expect("$request", matches(RegExp(r"^\d\d:\d\d:\d\d\.\d\d\d 🌐 GET ")));
  });

  test("keeps only the most recent messages", () {
    for (var i = 0; i < Logger.maxEntries + 10; i++) {
      Logger.info("Message $i");
    }

    expect(Logger.entries, hasLength(Logger.maxEntries));
    expect(Logger.entries.first.message, "Message 10");
  });

  test("notifies listeners once for messages logged in a row", () async {
    var notifications = 0;
    void listener() => notifications++;
    Logger.changes.addListener(listener);
    addTearDown(() => Logger.changes.removeListener(listener));
    await Future<void>.delayed(Duration.zero);
    notifications = 0;

    Logger.info("One");
    Logger.info("Two");
    expect(notifications, 0, reason: "not while logging");
    await Future<void>.delayed(Duration.zero);
    expect(notifications, 1);
  });
}
