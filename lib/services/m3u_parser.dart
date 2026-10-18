import "dart:convert";

import "package:streamhub/models/channel.dart";

/// M3U playlist parser
abstract final class M3uParser {
  /// Matches attributes like tvg-id="..." or group-title="..."
  static final _attributePattern = RegExp(r'([\w-]+)="([^"]*)"');

  /// Parses M3U playlist content and returns a list of channels
  static List<Channel> parse(String content) {
    final channels = <Channel>[];

    String? currentName;
    var attributes = const <String, String>{};

    for (final rawLine in LineSplitter.split(content)) {
      final line = rawLine.trim();

      if (line.isEmpty) continue;

      // EXTINF line: channel metadata followed by the display name
      if (line.startsWith("#EXTINF:")) {
        final separator = _titleSeparatorIndex(line);
        final header = separator == -1 ? line : line.substring(0, separator);
        final title = separator == -1 ? "" : line.substring(separator + 1);

        attributes = {
          for (final match in _attributePattern.allMatches(header)) match.group(1)!: match.group(2)!,
        };

        final name = title.trim();
        currentName = name.isNotEmpty ? name : attributes["tvg-name"];
      }
      // URL line (doesn't start with #)
      else if (!line.startsWith("#") && currentName != null) {
        channels.add(
          Channel(
            name: currentName,
            url: line,
            tvgId: attributes["tvg-id"],
            tvgName: attributes["tvg-name"],
            tvgLogo: attributes["tvg-logo"],
            groupTitle: attributes["group-title"],
          ),
        );

        // Reset for next channel
        currentName = null;
        attributes = const {};
      }
    }

    return channels;
  }

  /// Finds the comma that separates the EXTINF attributes from the channel
  /// name, ignoring commas inside quoted attribute values
  static int _titleSeparatorIndex(String line) {
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      switch (line[i]) {
        case '"':
          inQuotes = !inQuotes;
        case "," when !inQuotes:
          return i;
      }
    }
    return -1;
  }
}
