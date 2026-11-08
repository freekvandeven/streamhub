/// Hides credentials in URLs, so they can be logged and shared safely.
///
/// IPTV providers put the username and password of an account in playlist
/// and stream URLs, e.g. `get.php?username=...&password=...` or
/// `/live/<username>/<password>/1234.ts`.
library;

/// Query parameters whose values never contain credentials
const _safeQueryParameters = {"type", "output", "action", "format"};

/// `scheme://[userinfo@]host[:port][path][?query][#fragment]`
final _urlParts = RegExp(
  r"^([a-z][a-z0-9+.-]*://)(?:([^@/?#]*)@)?([^/?#]*)([^?#]*)(?:\?([^#]*))?(#.*)?$",
  caseSensitive: false,
);

/// Xtream Codes stream paths: `/live/<username>/<password>/...`
final _xtreamPath = RegExp("^/(live|movie|series|timeshift)/[^/]+/[^/]+/", caseSensitive: false);

/// Short Xtream Codes stream paths: `/<username>/<password>/1234.ts`
final _shortXtreamPath = RegExp(r"^/[^/]+/[^/]+/(\d+(?:\.\w+)?)$");

/// URLs in a piece of text
final _urlsInText = RegExp(r"""\b[a-z][a-z0-9+.-]*://[^\s"'<>]+""", caseSensitive: false);

/// Hides the credentials in [url]: user info, the values of query parameters
/// and the username and password in Xtream Codes stream paths
String redactUrl(String url) {
  final match = _urlParts.firstMatch(url);
  if (match == null) return url;
  final [scheme, userInfo, host, path, query, fragment] = [for (var i = 1; i <= 6; i++) match[i]];

  return [
    scheme!,
    if (userInfo != null) "***@",
    host!,
    _redactPath(path!),
    if (query != null) "?${_redactQuery(query)}",
    if (fragment != null) "#***",
  ].join();
}

/// Hides the credentials of all URLs in [text], see [redactUrl]
String redactUrls(String text) => text.replaceAllMapped(_urlsInText, (match) => redactUrl(match[0]!));

String _redactPath(String path) {
  if (_xtreamPath.firstMatch(path) case final match?) {
    return "/${match[1]}/***/***/${path.substring(match.end)}";
  }
  if (_shortXtreamPath.firstMatch(path) case final match?) {
    return "/***/***/${match[1]}";
  }
  return path;
}

String _redactQuery(String query) {
  return [
    for (final parameter in query.split("&"))
      switch (parameter.split("=")) {
        [""] => "",
        [final name, ...] when _safeQueryParameters.contains(name.toLowerCase()) => parameter,
        [final name, _, ...] => "$name=***",
        _ => "***",
      },
  ].join("&");
}
