import "package:http/http.dart" as http;

/// Creates a client. Browsers don't allow limiting how long connecting to a
/// server may take, so [connectTimeout] is ignored.
http.Client createHttpClient({required Duration connectTimeout}) => http.Client();
