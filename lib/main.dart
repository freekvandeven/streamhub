import "package:firebase_core/firebase_core.dart";
import "package:flutter/foundation.dart";
import "package:flutter_native_splash/flutter_native_splash.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:streamhub/firebase_options.dart";
import "package:streamhub/router/app_router.dart";
import "package:streamhub/services/playlist_storage.dart";

/// Whether this platform is registered with Firebase. Keep in sync with the
/// platforms passed to `flutterfire configure`.
bool get _isFirebaseConfigured => kIsWeb || defaultTargetPlatform == TargetPlatform.android;

Future<void> main() async {
  // Keep the native splash screen visible while initializing
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (_isFirebaseConfigured) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  await PlaylistStorage.init();

  runApp(const ProviderScope(child: MyApp()));
  FlutterNativeSplash.remove();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: "StreamHub",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
      // chewie still uses package:flutter/material.dart, so its controls and
      // fullscreen route need the legacy Theme and MaterialLocalizations.
      // Remove once chewie has migrated to material_ui.
      // ignore: deprecated_member_use
      builder: (context, child) => MaterialUiCompatibilityBridge(child: child!),
    );
  }
}
