import "package:channel_categorizer/channel_categorizer.dart";
import "package:streamhub/models/channel.dart";

/// Smart channel categorization service
/// Assigns hierarchical category paths using the channel_categorizer package
abstract final class ChannelCategorizer {
  static const ChannelCategorizerInterface _categorizer = DefaultChannelCategorizer();

  /// Returns copies of [channels] whose group title is replaced by a
  /// hierarchical category path (e.g. "Live TV > Sports > UK Sports")
  static List<Channel> categorize(List<Channel> channels) {
    return [
      for (final channel in channels)
        channel.copyWith(
          groupTitle: _categorizer
              .categorizeChannel(
                name: channel.name,
                url: channel.url,
                tvgId: channel.tvgId,
                tvgName: channel.tvgName,
                groupTitle: channel.groupTitle,
              )
              .categoryPath,
        ),
    ];
  }
}
