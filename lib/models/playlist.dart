import "package:streamhub/models/channel.dart";

/// Represents a complete playlist with metadata
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.url,
    required this.channels,
    required this.lastUpdate,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json["id"] as String,
      name: json["name"] as String,
      url: json["url"] as String,
      channels: [
        // Hive returns nested maps as Map<dynamic, dynamic>
        for (final channel in json["channels"] as List<dynamic>)
          Channel.fromJson(Map<String, dynamic>.from(channel as Map)),
      ],
      lastUpdate: DateTime.parse(json["lastUpdate"] as String),
    );
  }

  /// Unique identifier for the playlist
  final String id;

  /// User-provided name for the playlist
  final String name;

  /// URL where the playlist was loaded from
  final String url;

  /// List of channels in the playlist
  final List<Channel> channels;

  /// When the playlist was last updated
  final DateTime lastUpdate;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "url": url,
      "channels": [for (final channel in channels) channel.toJson()],
      "lastUpdate": lastUpdate.toIso8601String(),
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? url,
    List<Channel>? channels,
    DateTime? lastUpdate,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      channels: channels ?? this.channels,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  @override
  String toString() =>
      "Playlist(id: $id, name: $name, channels: ${channels.length})";
}
