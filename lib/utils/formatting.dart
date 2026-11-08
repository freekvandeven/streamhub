/// Formats a channel count, e.g. "1 channel" or "12 channels"
String formatChannelCount(int count) => count == 1 ? "1 channel" : "$count channels";

/// Formats a number of bytes, e.g. "512 B" or "1.50 MB"
String formatBytes(int bytes) {
  const units = ["B", "KB", "MB", "GB"];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return unit == 0 ? "$bytes B" : "${size.toStringAsFixed(2)} ${units[unit]}";
}

/// Formats a duration, e.g. "350 ms", "45.2 s", "5 min" or "1 min 22 s"
String formatDuration(Duration duration) {
  final milliseconds = duration.inMilliseconds;
  if (milliseconds < 1000) return "$milliseconds ms";
  if (milliseconds < 60000) {
    return milliseconds % 1000 == 0 ? "${milliseconds ~/ 1000} s" : "${(milliseconds / 1000).toStringAsFixed(1)} s";
  }
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return seconds == 0 ? "$minutes min" : "$minutes min $seconds s";
}
