import "package:flutter/material.dart";
import "package:flutter_native_splash/flutter_native_splash.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/providers/init_provider.dart";
import "package:streamhub/services/playlist_storage.dart";

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  String _loadingMessage = "Initializing...";
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Start initialization without awaiting (runs in background)
    // ignore: discarded_futures
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Remove native splash screen
      FlutterNativeSplash.remove();

      // Initialize local storage
      setState(() => _loadingMessage = "Initializing storage...");
      await PlaylistStorage.init();

      // Mark as initialized
      ref.read(initializationProvider.notifier).state = true;

      // Small delay to show completion
      setState(() => _loadingMessage = "Ready!");
      await Future.delayed(const Duration(milliseconds: 500));

      // Router will automatically redirect to appropriate route
      if (mounted) {
        context.go("/");
      }
    } on Exception catch (e) {
      setState(() {
        _hasError = true;
        _loadingMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "StreamHub",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 30),
              if (!_hasError) ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  _loadingMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _loadingMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _hasError = false;
                      _loadingMessage = "Retrying...";
                    });
                    await _initialize();
                  },
                  child: const Text("Retry"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
