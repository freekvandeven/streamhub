import "dart:developer" as developer;
import "dart:io";

import "package:http/http.dart" as http;

/// Simple HTTP service for fetching playlists
class HttpService {
  /// Fetches playlist content from URL
  static Future<String> fetchPlaylist(String url) async {
    developer.log("Fetching playlist from: $url");
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("HTTP ${response.statusCode}: Failed to load playlist");
      }
    } on SocketException catch (e) {
      // CORS errors often manifest as SocketException on web
      throw Exception(
        "Failed to load playlist.\n\n"
        "If you're using the web version:\n"
        "• Use a CORS-enabled playlist (like the demo playlist)\n"
        "• For private playlists, use the mobile/desktop app instead\n\n"
        "Original error: $e"
      );
    } catch (e) {
      developer.log("Fetch failed: $e");
      rethrow;
    }
  }
}
