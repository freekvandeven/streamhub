import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_native_splash/flutter_native_splash.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/router/app_router.dart";

Future<void> main() async {
  // Preserve splash screen until Flutter is ready
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Load environment variables (quick operation)
  await dotenv.load(fileName: "dotenv");

  // Run app - splash will be removed in LoadingScreen
  runApp(const ProviderScope(child: MyApp()));
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
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
