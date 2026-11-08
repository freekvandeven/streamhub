import "package:firebase_core/firebase_core.dart";
import "package:flutter/foundation.dart";
import "package:flutter_native_splash/flutter_native_splash.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:streamhub/firebase_options.dart";
import "package:streamhub/router/app_router.dart";
import "package:streamhub/utils/logger.dart";

/// Whether this platform is registered with Firebase. Keep in sync with the
/// platforms passed to `flutterfire configure`.
bool get _isFirebaseConfigured => kIsWeb || defaultTargetPlatform == TargetPlatform.android;

Future<void> main() async {
  // Keep the native splash screen visible while initializing
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  _logUncaughtErrors();

  if (_isFirebaseConfigured) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  await Hive.initFlutter();

  runApp(const ProviderScope(child: MyApp()));
  FlutterNativeSplash.remove();
}

/// Keeps uncaught errors in the in-app debug log, besides reporting them as
/// usual, so they can also be found in release builds
void _logUncaughtErrors() {
  final presentError = FlutterError.onError;
  FlutterError.onError = (details) {
    Logger.uncaughtError(details.exception, details.stack);
    presentError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    Logger.uncaughtError(error, stackTrace);
    // Not handled, so it's still reported
    return false;
  };
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
