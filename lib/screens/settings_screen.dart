import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";

class SettingsScreen extends HookWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packageInfo = useFuture(useMemoized(PackageInfo.fromPlatform)).data;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Content",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: const Text("Playlists"),
            subtitle: const Text("Manage your playlists"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push("/settings/playlists"),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "About",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Version"),
            subtitle: Text(
              packageInfo == null ? "" : "${packageInfo.version} (${packageInfo.buildNumber})",
            ),
          ),
        ],
      ),
    );
  }
}
