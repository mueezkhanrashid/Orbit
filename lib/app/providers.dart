import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/orbit_services.dart';
import '../core/services/jobs_service.dart';
import '../core/services/scholarship_service.dart';
import '../core/services/news_service.dart';
import '../core/location/location_service.dart';
import '../core/ai/advanced_ai_engine.dart';
import '../core/network/dio_client.dart';
import '../core/analytics/analytics_service.dart';
import '../core/data/orbit_advanced_repository.dart';
import '../core/models/orbit_models.dart';
import 'package:dio/dio.dart';

// Core
final dioProvider = Provider<Dio>((_) => OrbitDio.create());
final orbitServicesProvider = Provider<OrbitServices>((ref) => OrbitServices(dio: ref.read(dioProvider)));
final analyticsProvider = Provider<OrbitAnalytics>((_) => OrbitAnalytics());
final locationServiceProvider = Provider<LocationService>((ref) => LocationService(dio: ref.read(dioProvider)));
final advancedRepositoryProvider = Provider<OrbitAdvancedRepository>((ref) => OrbitAdvancedRepository(dio: ref.read(dioProvider)));

// Location — real-time, user-aware, cached 1h, falls back to Rawalpindi
final locationProvider = FutureProvider<OrbitLocation>((ref) async {
  final svc = ref.read(locationServiceProvider);
  return svc.current();
});
// Watch stream — UI can listen for moves (Space ISS, weather refresh)
final locationStreamProvider = StreamProvider<OrbitLocation>((ref) {
  final svc = ref.read(locationServiceProvider);
  return svc.watch();
});

// Domain — all location-aware, FAST 0ms via FastCache + currentFastSync + background GPS
final weatherProvider = FutureProvider<WeatherNow>((ref) async {
  // Instant location without awaiting GPS (0ms)
  var loc = ref.read(locationServiceProvider).currentFastSync();
  // Kick background GPS refresh once per session (does not block)
  // ignore: discarded_futures
  ref.read(locationServiceProvider).current(requestPermission: false).then((l){ if(l.city != loc.city) ref.invalidateSelf(); }).catchError((_) {});
  // Keep listening to locationProvider for when GPS finally resolves
  ref.listen(locationProvider, (prev, next) { if(next.hasValue && next.value!.city != loc.city) ref.invalidateSelf(); });
  return ref.read(orbitServicesProvider).weather(loc);
});

final marketsProvider = FutureProvider<List<MarketTick>>((ref) async {
  var loc = ref.read(locationServiceProvider).currentFastSync();
  // ignore: discarded_futures
  ref.read(locationServiceProvider).current(requestPermission: false).then((l){ if(l.city != loc.city) ref.invalidateSelf(); }).catchError((_) {});
  ref.listen(locationProvider, (prev, next) { if(next.hasValue && next.value!.city != loc.city) ref.invalidateSelf(); });
  return ref.read(orbitServicesProvider).markets(loc: loc);
});

final namazProvider = FutureProvider<List<NamazRow>>((ref) async {
  var loc = ref.read(locationServiceProvider).currentFastSync();
  // ignore: discarded_futures
  ref.read(locationServiceProvider).current(requestPermission: false).then((l){ if(l.city != loc.city) ref.invalidateSelf(); }).catchError((_) {});
  ref.listen(locationProvider, (prev, next) { if(next.hasValue && next.value!.city != loc.city) ref.invalidateSelf(); });
  return ref.read(orbitServicesProvider).namaz(loc);
});

final ayahProvider = FutureProvider<Ayah>((ref) async {
  return ref.read(orbitServicesProvider).ayahOfDay();
});

// Jobs/Scholarships/News — location filters applied client-side but also scope params
final jobsServiceProvider = Provider<JobsService>((ref) => JobsService(dio: ref.read(dioProvider)));
final scholarshipServiceProvider = Provider<ScholarshipService>((_) => ScholarshipService());
final newsServiceProvider = Provider<NewsService>((ref) => NewsService(dio: ref.read(dioProvider)));

// Zikar + locale + search
final zikarProvider = StateProvider<int>((_) => 12);
final localeProvider = StateProvider<String>((_) => 'en');
final searchQueryProvider = StateProvider<String>((_) => '');

// Manual location override — null = auto GPS, else manual city
final manualLocationProvider = StateProvider<OrbitLocation?>((_) => null);

// Advanced AI + Performance
final advancedAiProvider = Provider<AdvancedAiEngine>((_) => AdvancedAiEngine());
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.light); // Advanced: dark mode toggle
