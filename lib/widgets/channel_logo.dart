import "package:material_ui/material_ui.dart";

/// Shows a channel's logo, falling back to a TV icon
class ChannelLogo extends StatelessWidget {
  const ChannelLogo({
    required this.url,
    required this.size,
    this.fallbackColor,
    super.key,
  });

  final String? url;
  final double size;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.tv, size: size, color: fallbackColor);
    final logoUrl = url;
    if (logoUrl == null || logoUrl.isEmpty) return fallback;

    return Image.network(
      logoUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // Logos are often large; decode them at the size they are shown
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
