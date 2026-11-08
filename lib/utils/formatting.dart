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
