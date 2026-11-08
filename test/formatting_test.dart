import "package:flutter_test/flutter_test.dart";
import "package:streamhub/utils/formatting.dart";

void main() {
  test("formatChannelCount uses the singular for one channel", () {
    expect(formatChannelCount(0), "0 channels");
    expect(formatChannelCount(1), "1 channel");
    expect(formatChannelCount(2052), "2052 channels");
  });

  test("formatBytes picks a readable unit", () {
    expect(formatBytes(512), "512 B");
    expect(formatBytes(1536), "1.50 KB");
    expect(formatBytes(256 * 1024 * 1024), "256.00 MB");
    expect(formatBytes(3 * 1024 * 1024 * 1024), "3.00 GB");
  });
}
