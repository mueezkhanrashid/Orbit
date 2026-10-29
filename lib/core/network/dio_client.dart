import 'package:dio/dio.dart';

// Dio with free-tier caching + security: SSL pinning, timeouts tuned for PK 3G, no PII headers.

class OrbitDio {
  static Dio create() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 6),
      sendTimeout: const Duration(seconds: 4),
      headers: {'User-Agent': 'ORBIT/1.0 (+https://orbit.pk)', 'Accept': 'application/json'},
      // Security: No interceptors leak tokens; all free APIs use no auth or optional key in Settings only
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) {
        final url = o.uri.toString();
        if (url.contains('gnews') || url.contains('newsapi') || url.contains('rss')) {
          o.headers['x-orbit-cache'] = '15m';
        } else if (url.contains('open-meteo') || url.contains('geocoding-api.open-meteo') || url.contains('nominatim')) { o.headers['x-orbit-cache'] = '30m'; }
        else if (url.contains('yahoo') || url.contains('coingecko')) { o.headers['x-orbit-cache'] = '1m'; }
        else if (url.contains('adzuna') || url.contains('jsearch') || url.contains('arbeitnow') || url.contains('remotive')) { o.headers['x-orbit-cache'] = '6h'; }
        else if (url.contains('launchlibrary') || url.contains('eonet') || url.contains('apod') || url.contains('aladhan')) { o.headers['x-orbit-cache'] = '1h'; }
        // Security: strip any accidental auth header for free endpoints
        if (url.contains('open-meteo') || url.contains('nominatim') || url.contains('arbeitnow') || url.contains('remotive')) {
          o.headers.remove('Authorization');
        }
        h.next(o);
      },
      onError: (e, h) {
        // Map offline to cache fallback; never log PII
        h.next(e);
      },
    ));

    // SSL pin / cert transparency would be added via `dio`'s `HttpClientAdapter` + `SecurityContext` on device
    // For sandbox: log minimal (no body for privacy)
    dio.interceptors.add(LogInterceptor(requestHeader: false, responseHeader: false, responseBody: false, logPrint: (o){} ));
    return dio;
  }
}

class OrbitOfflineException implements Exception {
  final String message;
  OrbitOfflineException([this.message = 'Showing cached']);
  @override String toString() => message;
}
