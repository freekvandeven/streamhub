import "package:streamhub/utils/logger.dart";
import "package:wakelock_plus/wakelock_plus.dart";

/// Keeps the screen on while anything holds the wakelock, such as a split
/// screen or a playlist download. Holders are counted, so one letting go
/// doesn't turn the screen off for another.
abstract final class Wakelock {
  static var _holders = 0;

  /// Keeps the screen on until a matching [release]
  static Future<void> acquire() async {
    _holders++;
    if (_holders == 1) await _set(enabled: true);
  }

  /// Lets the screen turn off again, once nothing else holds the wakelock
  static Future<void> release() async {
    if (_holders == 0) return;
    _holders--;
    if (_holders == 0) await _set(enabled: false);
  }

  static Future<void> _set({required bool enabled}) async {
    try {
      await WakelockPlus.toggle(enable: enabled);
    } on Object catch (e) {
      // Not available on every platform, nor in tests
      Logger.warning("Couldn't ${enabled ? "enable" : "disable"} the wakelock: $e");
    }
  }
}
