/// A single playable entry from an M3U playlist
class Channel {
  const Channel({
    required this.name,
    required this.url,
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    this.groupTitle,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      name: json["name"] as String,
      url: json["url"] as String,
      tvgId: json["tvgId"] as String?,
      tvgName: json["tvgName"] as String?,
      tvgLogo: json["tvgLogo"] as String?,
      groupTitle: json["groupTitle"] as String?,
    );
  }

  final String name;
  final String url;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final String? groupTitle;

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "url": url,
      "tvgId": tvgId,
      "tvgName": tvgName,
      "tvgLogo": tvgLogo,
      "groupTitle": groupTitle,
    };
  }

  Channel copyWith({String? groupTitle}) {
    return Channel(
      name: name,
      url: url,
      tvgId: tvgId,
      tvgName: tvgName,
      tvgLogo: tvgLogo,
      groupTitle: groupTitle ?? this.groupTitle,
    );
  }

  @override
  String toString() {
    return "Channel(name: $name, group: $groupTitle, url: $url)";
  }
}

/// Channels that share the same category
class ChannelCategory {
  const ChannelCategory({required this.name, required this.channels});

  final String name;
  final List<Channel> channels;
}
