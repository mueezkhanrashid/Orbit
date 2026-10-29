import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../storage/hive_boxes.dart';

import '../cache/fast_cache.dart';

// Real-time location — free, no paid key.
// Uses geolocator (permission + GPS) + Open-Meteo reverse geocode (free, no key) + Nominatim fallback.
// Every data card then follows location: weather, namaz, news scope, jobs filter, qibla.
// FAST PATH: currentFastSync() returns cached/Hive at 0ms for instant rendering.

class OrbitLocation {
  final double lat, lng;
  final String city, country, countryCode;
  final double? accuracy;
  const OrbitLocation({required this.lat, required this.lng, required this.city, required this.country, required this.countryCode, this.accuracy});
  factory OrbitLocation.rawalpindi() => const OrbitLocation(lat: 33.5651, lng: 73.0169, city: 'Rawalpindi', country: 'Pakistan', countryCode: 'PK');
  Map<String,dynamic> toJson()=> {'lat':lat,'lng':lng,'city':city,'country':country,'countryCode':countryCode};
  factory OrbitLocation.fromJson(Map<String,dynamic> j)=> OrbitLocation(lat:(j['lat'] as num).toDouble(), lng:(j['lng'] as num).toDouble(), city:j['city'], country:j['country'], countryCode:j['countryCode']);
  String get label => '$city • $country';
}

class LocationService {
  final Dio _dio;
  LocationService({Dio? dio}) : _dio = dio ?? OrbitDio.create();

  // FAST 0ms — for providers to render instantly, before GPS.
  OrbitLocation currentFastSync() {
    // 1) memory
    final mem = FastCache().peek<OrbitLocation>('orbit_location_fast');
    if (mem != null) return mem;
    // 2) Hive 1h
    final cached = OrbitBoxes.getCached(OrbitBoxes.prefs, 'orbit_location', const Duration(hours: 1));
    if (cached != null) {
      try {
        final loc = OrbitLocation.fromJson(Map<String,dynamic>.from(cached));
        FastCache().set('orbit_location_fast', loc);
        return loc;
      } catch(_){}
    }
    // 3) Last known manual/raw
    final last = OrbitBoxes.box(OrbitBoxes.prefs).get('orbit_location');
    if (last is Map) {
      try { final loc = OrbitLocation.fromJson(Map<String,dynamic>.from(last)); FastCache().set('orbit_location_fast', loc); return loc; } catch(_){}
    }
    return OrbitLocation.rawalpindi();
  }

  // Call once on app start, then watchPosition for real-time moves.
  Future<OrbitLocation> current({bool requestPermission=true}) async {
    // 1. Try cached (1h) — instant 0ms + FastCache
    final fast = FastCache().get<OrbitLocation>('orbit_location_fast', const Duration(hours: 1));
    if (fast != null) return fast;
    final cached = OrbitBoxes.getCached(OrbitBoxes.prefs, 'orbit_location', const Duration(hours: 1));
    if (cached != null) {
      try { final loc = OrbitLocation.fromJson(Map<String,dynamic>.from(cached)); FastCache().set('orbit_location_fast', loc); return loc; } catch(_){}
    }

    // 2. Permission + GPS
    if (requestPermission) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _fallback('Location off');
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return _fallback('Permission denied');
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 4));
      final loc = await _reverse(pos.latitude, pos.longitude, accuracy: pos.accuracy);
      // Cache + FastCache 0ms next time
      OrbitBoxes.putCached(OrbitBoxes.prefs, 'orbit_location', {...loc.toJson(), '_cachedAt': DateTime.now().toIso8601String()});
      FastCache().set('orbit_location_fast', loc);
      OrbitBoxes.box(OrbitBoxes.prefs).put('orbit_location_manual', false);
      return loc;
    } catch (_) {
      return _fallback('GPS timeout');
    }
  }

  // Manual override (user picks city in header)
  Future<OrbitLocation> setManual(String city, double lat, double lng, String country, String cc) async {
    final loc = OrbitLocation(lat: lat, lng: lng, city: city, country: country, countryCode: cc);
    OrbitBoxes.putCached(OrbitBoxes.prefs, 'orbit_location', {...loc.toJson(), '_cachedAt': DateTime.now().toIso8601String()});
    FastCache().set('orbit_location_fast', loc);
    OrbitBoxes.box(OrbitBoxes.prefs).put('orbit_location_manual', true);
    OrbitBoxes.box(OrbitBoxes.prefs).put('orbit_location_manual_city', city);
    return loc;
  }

  bool get isManual => OrbitBoxes.box(OrbitBoxes.prefs).get('orbit_location_manual')==true;

  // Real-time stream — 25m movement or 30s
  Stream<OrbitLocation> watch() {
    return Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, distanceFilter: 25)).asyncMap((pos) async {
      final loc = await _reverse(pos.latitude, pos.longitude, accuracy: pos.accuracy);
      OrbitBoxes.putCached(OrbitBoxes.prefs, 'orbit_location', {...loc.toJson(), '_cachedAt': DateTime.now().toIso8601String()});
      FastCache().set('orbit_location_fast', loc);
      return loc;
    });
  }

  Future<OrbitLocation> _reverse(double lat, double lng, {double? accuracy}) async {
    // 1) Open-Meteo reverse (free, no key)
    try {
      final r = await _dio.get('https://geocoding-api.open-meteo.com/v1/reverse', queryParameters: {'latitude': lat, 'longitude': lng, 'language': 'en'});
      final results = r.data['results'] as List?;
      if (results!=null && results.isNotEmpty) {
        final first = Map<String,dynamic>.from(results.first as Map);
        return OrbitLocation(
          lat: lat, lng: lng,
          city: (first['name']?? first['admin1']?? 'Nearby').toString(),
          country: (first['country']?? 'Pakistan').toString(),
          countryCode: (first['country_code']?? 'PK').toString(),
          accuracy: accuracy,
        );
      }
    } catch(_){}
    // 2) Nominatim fallback (free, no key, needs User-Agent)
    try {
      final r = await _dio.get('https://nominatim.openstreetmap.org/reverse', queryParameters: {'lat': lat, 'lon': lng, 'format': 'json', 'zoom': '10', 'accept-language': 'en'}, options: Options(headers:{'User-Agent':'ORBIT/1.0'}));
      final addr = r.data['address'] as Map<String,dynamic>? ?? {};
      return OrbitLocation(
        lat: lat, lng: lng,
        city: (addr['city']?? addr['town']?? addr['village']?? addr['state']?? 'Nearby').toString(),
        country: (addr['country']?? 'Pakistan').toString(),
        countryCode: (addr['country_code']?? 'pk').toString().toUpperCase(),
        accuracy: accuracy,
      );
    } catch(_){}
    return OrbitLocation(lat: lat, lng: lng, city: 'Nearby', country: 'Pakistan', countryCode: 'PK', accuracy: accuracy);
  }

  OrbitLocation _fallback(String reason){
    // Use last cached if exists, else Rawalpindi
    final cached = OrbitBoxes.box(OrbitBoxes.prefs).get('orbit_location');
    if (cached is Map) {
      try { return OrbitLocation.fromJson(Map<String,dynamic>.from(cached)); } catch(_){}
    }
    return OrbitLocation.rawalpindi();
  }

  // Free city search for manual picker — Open-Meteo search
  Future<List<OrbitLocation>> searchCity(String q) async {
    if (q.trim().length < 2) return [];
    try {
      final r = await _dio.get('https://geocoding-api.open-meteo.com/v1/search', queryParameters: {'name': q, 'count': 6, 'language': 'en', 'format':'json'});
      final results = r.data['results'] as List? ?? [];
      return results.map((e){
        final m = Map<String,dynamic>.from(e as Map);
        return OrbitLocation(lat:(m['latitude'] as num).toDouble(), lng:(m['longitude'] as num).toDouble(), city:(m['name']).toString(), country:(m['country']??'').toString(), countryCode:(m['country_code']??'').toString().toUpperCase());
      }).toList();
    } catch(_){ return [];}
  }
}
