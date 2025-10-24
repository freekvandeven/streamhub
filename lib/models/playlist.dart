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
    final channelsJson = json["channels"] as List<dynamic>;
    final channels = channelsJson.map<Channel>((channelJson) {
      // Handle both Map<String, dynamic> and Map<dynamic, dynamic>
      final map = channelJson is Map<String, dynamic>
          ? channelJson
          : (channelJson as Map<dynamic, dynamic>).map(
              (key, value) => MapEntry(key.toString(), value),
            );
      return Channel(
        name: map["name"] as String,
        url: map["url"] as String,
        tvgId: map["tvgId"] as String?,
        tvgName: map["tvgName"] as String?,
        tvgLogo: map["tvgLogo"] as String?,
        groupTitle: map["groupTitle"] as String?,
      );
    }).toList();

    return Playlist(
      id: json["id"] as String,
      name: json["name"] as String,
      url: json["url"] as String,
      channels: channels,
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
      "channels": channels
          .map(
            (c) => {
              "name": c.name,
              "url": c.url,
              "tvgId": c.tvgId,
              "tvgName": c.tvgName,
              "tvgLogo": c.tvgLogo,
              "groupTitle": c.groupTitle,
            },
          )
          .toList(),
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
