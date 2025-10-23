import "package:iptv_app/models/channel.dart";

/// M3U playlist parser
abstract final class M3uParser {
  /// Parses M3U playlist content and returns a list of channels
  static List<Channel> parse(String content) {
    final channels = <Channel>[];
    final lines = content.split("\n");

    String? currentName;
    String? currentUrl;
    String? tvgId;
    String? tvgName;
    String? tvgLogo;
    String? groupTitle;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      // Check for EXTINF line (contains channel metadata)
      if (line.startsWith("#EXTINF:")) {
        // Extract attributes from EXTINF line
        final attributes = _parseExtinfLine(line);

        tvgId = attributes["tvg-id"];
        tvgName = attributes["tvg-name"];
        tvgLogo = attributes["tvg-logo"];
        groupTitle = attributes["group-title"];

        // Extract channel name (after the comma)
        final commaIndex = line.lastIndexOf(",");
        if (commaIndex != -1 && commaIndex < line.length - 1) {
          currentName = line.substring(commaIndex + 1).trim();
        }
      }
      // Check for URL line (doesn't start with #)
      else if (!line.startsWith("#") && currentName != null) {
        currentUrl = line;

        // Create channel object
        channels.add(
          Channel(
            name: currentName,
            url: currentUrl,
            tvgId: tvgId,
            tvgName: tvgName,
            tvgLogo: tvgLogo,
            groupTitle: groupTitle,
          ),
        );

        // Reset for next channel
        currentName = null;
        currentUrl = null;
        tvgId = null;
        tvgName = null;
        tvgLogo = null;
        groupTitle = null;
      }
    }

    return channels;
  }

  /// Parses attributes from EXTINF line
  static Map<String, String> _parseExtinfLine(String line) {
    final attributes = <String, String>{};

    // Match attributes like tvg-id="..." or group-title="..."
    final regex = RegExp(r'(\w+-?\w+)="([^"]*)"');
    final matches = regex.allMatches(line);

    for (final match in matches) {
      if (match.groupCount >= 2) {
        final key = match.group(1);
        final value = match.group(2);
        if (key != null && value != null) {
          attributes[key] = value;
        }
      }
    }

    return attributes;
  }
}
