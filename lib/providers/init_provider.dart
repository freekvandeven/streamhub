import "package:hooks_riverpod/hooks_riverpod.dart";

/// Provider to track app initialization state
final initializationProvider = StateProvider<bool>((ref) => false);
