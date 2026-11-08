import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:streamhub/utils/logger.dart";

/// Shows what the app logged recently, to help find problems. Also works in
/// release builds, where nothing is printed.
class LogScreen extends HookWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    useListenable(Logger.changes);
    final packageInfo = useFuture(useMemoized(PackageInfo.fromPlatform)).data;
    final entries = Logger.entries;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Debug log"),
        backgroundColor: colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: "Copy log",
            onPressed: entries.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: _export(entries, packageInfo)));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Log copied")));
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Clear log",
            onPressed: entries.isEmpty ? null : Logger.clear,
          ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Text(
                "Nothing logged yet",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          : SelectionArea(
              // Newest at the bottom, where the list starts
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[entries.length - 1 - index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "$entry",
                      style: TextStyle(
                        fontFamily: "monospace",
                        fontSize: 12,
                        color: entry.level == LogLevel.error ? colorScheme.error : null,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  /// The log as text, with what's needed to make sense of it
  static String _export(List<LogEntry> entries, PackageInfo? packageInfo) {
    final app = packageInfo == null ? "StreamHub" : "StreamHub ${packageInfo.version} (${packageInfo.buildNumber})";
    final platform = kIsWeb ? "web" : defaultTargetPlatform.name;
    const mode = kReleaseMode ? "release" : (kProfileMode ? "profile" : "debug");
    return [
      "$app on $platform, $mode build",
      "Exported ${DateTime.now()}",
      "",
      ...entries.map((entry) => "$entry"),
    ].join("\n");
  }
}
