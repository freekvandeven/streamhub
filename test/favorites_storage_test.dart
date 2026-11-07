import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:streamhub/services/favorites_storage.dart";

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp("streamhub_favorites_");
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
  });

  test("starts empty and keeps favorites in the order they were added", () async {
    expect(await FavoritesStorage.load(), isEmpty);

    await FavoritesStorage.save(["b", "a", "c"]);
    expect(await FavoritesStorage.load(), ["b", "a", "c"]);

    await FavoritesStorage.save(["a"]);
    expect(await FavoritesStorage.load(), ["a"]);
  });
}
