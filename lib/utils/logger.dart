import "dart:async";
import "dart:collection";

import "package:flutter/foundation.dart";
import "package:streamhub/utils/redact.dart";

enum LogLevel {
  info("ℹ️"),
  success("✅"),
  warning("⚠️"),
  error("❌"),
  network("🌐"),
  data("📦");

  const LogLevel(this.symbol);

  final String symbol;
}

class LogEntry {
  const LogEntry(this.time, this.level, this.message);

  final DateTime time;
  final LogLevel level;
  final String message;

  @override
  String toString() {
    String pad(int value, [int width = 2]) => "$value".padLeft(width, "0");
    final timestamp = "${pad(time.hour)}:${pad(time.minute)}:${pad(time.second)}.${pad(time.millisecond, 3)}";
    return "$timestamp ${level.symbol} $message";
  }
}

/// Logs messages to the console in debug builds, and keeps the most recent
/// ones in memory in all builds, so they can be viewed and shared from the
/// app.
///
/// URLs in messages are redacted, as playlist and stream URLs often contain
/// the username and password of an account.
abstract final class Logger {
  /// How many messages are kept
  static const maxEntries = 1000;

  static final _entries = ListQueue<LogEntry>();
  static final _changes = _Changes();

  /// The kept messages, oldest first
  static List<LogEntry> get entries => List.unmodifiable(_entries);

  /// Notifies its listeners after messages were logged or cleared
  static Listenable get changes => _changes;

  static void clear() {
    _entries.clear();
    _changes.notify();
  }

  static void info(String message) => _log(LogLevel.info, message);

  static void success(String message) => _log(LogLevel.success, message);

  static void warning(String message) => _log(LogLevel.warning, message);

  static void error(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.error, stackTrace == null ? message : "$message\n$stackTrace");
  }

  static void network(String message) => _log(LogLevel.network, message);

  static void data(String message) => _log(LogLevel.data, message);

  /// Keeps an uncaught error without printing it, as Flutter already does
  static void uncaughtError(Object error, StackTrace? stackTrace) {
    _log(LogLevel.error, "Uncaught error: $error${stackTrace == null ? "" : "\n$stackTrace"}", print: false);
  }

  static void _log(LogLevel level, String message, {bool print = true}) {
    final entry = LogEntry(DateTime.now(), level, redactUrls(message));
    _entries.add(entry);
    while (_entries.length > maxEntries) {
      _entries.removeFirst();
    }
    if (print && kDebugMode) debugPrint("${level.symbol} ${entry.message}");
    _changes.notify();
  }
}

class _Changes extends ChangeNotifier {
  var _scheduled = false;

  /// Notifies listeners once for all messages logged in a row. Not right
  /// away, as messages may be logged while widgets build.
  void notify() {
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      notifyListeners();
    });
  }
}
