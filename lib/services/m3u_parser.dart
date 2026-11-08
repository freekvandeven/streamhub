import "dart:convert";

import "package:streamhub/models/channel.dart";

/// M3U playlist parser
abstract final class M3uParser {
  /// Parses M3U playlist content and returns a list of channels
  static List<Channel> parse(String content) {
    final channels = <Channel>[];
    final parser = M3uLineParser(channels.add);
    LineSplitter.split(content).forEach(parser.addLine);
    return channels;
  }

  /// Returns a sink for a playlist's UTF-8 content in chunks, for example as
  /// it downloads, that calls [onChannel] for each channel as soon as it's
  /// complete. Close the sink after the last chunk.
  static Sink<List<int>> parseChunks(void Function(Channel channel) onChannel) {
    final parser = M3uLineParser(onChannel);
    return const Utf8Decoder(allowMalformed: true).startChunkedConversion(
      const LineSplitter().startChunkedConversion(_LineSink(parser.addLine)),
    );
  }
}

/// Parses an M3U playlist one line at a time
class M3uLineParser {
  M3uLineParser(this._onChannel);

  /// Matches attributes like tvg-id="..." or group-title="..."
  static final _attributePattern = RegExp(r'([\w-]+)="([^"]*)"');

  final void Function(Channel channel) _onChannel;

  /// Thousands of channels can share a category, so keep one copy of each
  final _groups = <String, String>{};

  String? _name;
  var _attributes = const <String, String>{};

  void addLine(String rawLine) {
    final line = rawLine.trim();
    if (line.isEmpty) return;

    // EXTINF line: channel metadata followed by the display name
    if (line.startsWith("#EXTINF:")) {
      final separator = _titleSeparatorIndex(line);
      final header = separator == -1 ? line : line.substring(0, separator);
      final title = separator == -1 ? "" : line.substring(separator + 1);

      _attributes = {
        for (final match in _attributePattern.allMatches(header)) match.group(1)!: match.group(2)!,
      };

      final name = title.trim();
      _name = name.isNotEmpty ? name : _attributes["tvg-name"];
    }
    // URL line (doesn't start with #)
    else if (!line.startsWith("#") && _name != null) {
      final name = _name!;
      final tvgName = _attributes["tvg-name"];
      final group = _attributes["group-title"];
      _onChannel(
        Channel(
          name: name,
          url: line,
          tvgId: _attributes["tvg-id"],
          // Usually the same as the name, which saves memory in large playlists
          tvgName: tvgName == name ? null : tvgName,
          tvgLogo: _attributes["tvg-logo"],
          groupTitle: group == null ? null : _groups.putIfAbsent(group, () => group),
        ),
      );

      // Reset for next channel
      _name = null;
      _attributes = const {};
    }
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

class _LineSink implements Sink<String> {
  const _LineSink(this._onLine);

  final void Function(String line) _onLine;

  @override
  void add(String line) => _onLine(line);

  @override
  void close() {}
}
