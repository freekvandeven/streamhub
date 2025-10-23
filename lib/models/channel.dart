class Channel {
  final String name;
  final String url;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final String? groupTitle;

  Channel({
    required this.name,
    required this.url,
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    this.groupTitle,
  });

  @override
  String toString() {
    return 'Channel(name: $name, group: $groupTitle, url: $url)';
  }
}
