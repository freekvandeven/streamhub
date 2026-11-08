import "package:channel_categorizer/channel_categorizer.dart";
import "package:streamhub/models/channel.dart";

/// Smart channel categorization service
/// Assigns hierarchical category paths using the channel_categorizer package
abstract final class ChannelCategorizer {
  static const ChannelCategorizerInterface _categorizer = DefaultChannelCategorizer();

  /// One copy of each category path, since many channels share one
  static final _paths = <String, String>{};

  /// Returns copies of [channels] whose group title is replaced by a
  /// hierarchical category path (e.g. "Live TV > Sports > UK Sports")
  static List<Channel> categorize(List<Channel> channels) => channels.map(categorizeChannel).toList();

  /// Returns [channel] with a hierarchical category path as its group title.
  /// Returns [channel] itself when it already has a usable group title.
  static Channel categorizeChannel(Channel channel) {
    final path = _categorizer
        .categorizeChannel(
          name: channel.name,
          url: channel.url,
          tvgId: channel.tvgId,
          tvgName: channel.tvgName,
          groupTitle: channel.groupTitle,
        )
        .categoryPath;
    if (path == channel.groupTitle) return channel;

    return channel.copyWith(groupTitle: _paths.putIfAbsent(path, () => path));
  }
}
