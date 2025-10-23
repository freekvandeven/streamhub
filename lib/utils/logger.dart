import 'package:flutter/foundation.dart';

class Logger {
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ $message');
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ $message');
    }
  }

  static void error(String message) {
    if (kDebugMode) {
      debugPrint('❌ $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    }
  }

  static void network(String message) {
    if (kDebugMode) {
      debugPrint('🌐 $message');
    }
  }

  static void data(String message) {
    if (kDebugMode) {
      debugPrint('📦 $message');
    }
  }
}
