import "package:flutter_test/flutter_test.dart";
import "package:streamhub/utils/formatting.dart";

void main() {
  test("formatChannelCount uses the singular for one channel", () {
    expect(formatChannelCount(0), "0 channels");
    expect(formatChannelCount(1), "1 channel");
    expect(formatChannelCount(2052), "2052 channels");
  });
}
