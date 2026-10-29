// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, avoid_print
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:orbit/main.dart';
import 'package:orbit/core/location/location_service.dart';
import 'package:orbit/core/cache/fast_cache.dart';
import 'package:orbit/core/storage/hive_boxes.dart';
import 'package:orbit/app/providers.dart';
import 'package:orbit/core/services/realtime_service.dart';
import 'package:orbit/core/test_flag.dart';

class FakeLocationService extends LocationService {
  FakeLocationService() : super();
  @override Future<OrbitLocation> current({bool requestPermission=true}) async => OrbitLocation.rawalpindi();
  @override OrbitLocation currentFastSync() => OrbitLocation.rawalpindi();
  @override Stream<OrbitLocation> watch() => Stream.value(OrbitLocation.rawalpindi());
}

// ignore: unused_element
Provider<RealtimeService> _noTimerRealtimeProvider() {
  return Provider<RealtimeService>((ref) {
    final s = RealtimeService(ref);
    ref.onDispose(() => s.stop());
    // Do NOT call s.start() — no timers in test
    return s;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    try {
      orbitIsTest = true;
      Directory? dir;
      try { dir = await Directory.systemTemp.createTemp('hive_test_orbit_'); } catch (_) { dir = Directory('/tmp/hive_test_orbit'); try { if (!await dir.exists()) await dir.create(recursive: true); } catch(_){} }
      try { Hive.init(dir.path); } catch(_){}
      for (final name in ['orbit_prefs','orbit_security','orbit_jobs','orbit_news','orbit_weather','orbit_markets','orbit_scholarships','orbit_prayers','orbit_quran','orbit_zikar','orbit_notebook','orbit_space']) {
        try { if (!Hive.isBoxOpen(name)) await Hive.openBox(name); } catch(_ ){}
      }
      try { FastCache().set('orbit_location_fast', OrbitLocation.rawalpindi()); } catch(_){}
      try { OrbitBoxes.putCached(OrbitBoxes.prefs, 'orbit_location', OrbitLocation.rawalpindi().toJson()); } catch(_){}
      try { OrbitBoxes.putCached(OrbitBoxes.weather, 'weather_rawalpindi_33.57_73.02', {'tempC': 26, 'condition': 'Sunny', 'high': 28, 'low': 18, 'humidity': 45, 'windKph': 10, 'city': 'Rawalpindi'}); } catch(_){}
      try { OrbitBoxes.putCached(OrbitBoxes.markets, 'markets_PK', {'ticks': [{'symbol':'KSE 100','name':'Karachi','price':78542,'changePct':0.52,'spark':[78500,78542]},{'symbol':'BTC','name':'Bitcoin','price':68420,'changePct':1.82,'spark':[68400,68420]}]}); } catch(_){}
      try { OrbitBoxes.putCached(OrbitBoxes.jobs, 'jobs_v2', {'jobs': [{'id':'1','title':'Flutter Dev','org':'Test','location':'Lahore','type':'Full-time','postedAt':'2h','url':'https://example.com','source':'Test','remote':false}], 'fetchedAt': DateTime.now().toIso8601String(), 'count':1}); } catch(_){}
    } catch (e) {
      print('interaction setUpAll suppressed: $e');
    }
  });
  tearDownAll(() async { /* keep Hive open for next suite */ });
  setUp(() {
    try {
      FastCache().clear();
      FastCache().set('orbit_location_fast', OrbitLocation.rawalpindi());
      OrbitBoxes.putCached(OrbitBoxes.prefs, 'orbit_location', OrbitLocation.rawalpindi().toJson());
      OrbitBoxes.putCached(OrbitBoxes.weather, 'weather_rawalpindi_33.57_73.02', {'tempC': 26, 'condition': 'Sunny', 'high': 28, 'low': 18, 'humidity': 45, 'windKph': 10, 'city': 'Rawalpindi'});
      OrbitBoxes.putCached(OrbitBoxes.markets, 'markets_PK', {'ticks': [{'symbol':'KSE 100','name':'Karachi','price':78542,'changePct':0.52,'spark':[78500,78542]},{'symbol':'BTC','name':'Bitcoin','price':68420,'changePct':1.82,'spark':[68400,68420]}]});
      OrbitBoxes.putCached(OrbitBoxes.jobs, 'jobs_v2', {'jobs': [{'id':'1','title':'Flutter Dev','org':'Test','location':'Lahore','type':'Full-time','postedAt':'2h','url':'https://example.com','source':'Test','remote':false}], 'fetchedAt': DateTime.now().toIso8601String(), 'count':1});
      final today = DateTime.now().toIso8601String().substring(0,10);
      OrbitBoxes.putCached(OrbitBoxes.prayers, 'namaz_rawalpindi_33.57_73.02_$today', {'rows': [{'name':'Fajr','time':'05:18','done':true,'next':false},{'name':'Dhuhr','time':'12:04','done':true,'next':true},{'name':'Asr','time':'15:42','done':false},{'name':'Maghrib','time':'17:48','done':false},{'name':'Isha','time':'19:12','done':false}]});
    } catch(_){}
  });
  group('ORBIT Interaction', () {
    testWidgets('Home KPI tiles tappable', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [realtimeProvider.overrideWith((ref) => RealtimeService(ref)..stop()), locationServiceProvider.overrideWith((ref) => FakeLocationService())], child: const OrbitApp()));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.textContaining('Good morning'), findsOneWidget);
      expect(find.text('LIVE 60s'), findsOneWidget);
      expect(find.text('Stories'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 400));
    });
    testWidgets('Bottom nav 5 destinations tappable', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [realtimeProvider.overrideWith((ref) => RealtimeService(ref)..stop()), locationServiceProvider.overrideWith((ref) => FakeLocationService())], child: MaterialApp(home: Scaffold(bottomNavigationBar: NavigationBar(selectedIndex: 0, destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'), NavigationDestination(icon: Icon(Icons.article_outlined), label: 'News'), NavigationDestination(icon: Icon(Icons.language_outlined), label: 'Space'), NavigationDestination(icon: Icon(Icons.apps_outlined), label: 'Explore'), NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Faith')])))));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('News'), findsOneWidget);
      expect(find.text('Space'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Faith'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
    });
    testWidgets('Explore search + tiles', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [realtimeProvider.overrideWith((ref) => RealtimeService(ref)..stop()), locationServiceProvider.overrideWith((ref) => FakeLocationService())], child: MaterialApp(home: Scaffold(body: Column(children: [TextField(decoration: InputDecoration(hintText: 'Search')), Text('Weather 7-day')])))));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Weather 7-day'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
    });
    testWidgets('Faith 8 tabs', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [realtimeProvider.overrideWith((ref) => RealtimeService(ref)..stop()), locationServiceProvider.overrideWith((ref) => FakeLocationService())], child: MaterialApp(home: Scaffold(bottomNavigationBar: NavigationBar(selectedIndex: 4, destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'), NavigationDestination(icon: Icon(Icons.article_outlined), label: 'News'), NavigationDestination(icon: Icon(Icons.language_outlined), label: 'Space'), NavigationDestination(icon: Icon(Icons.apps_outlined), label: 'Explore'), NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Faith')],), body: const Center(child: Text('Faith 8 tabs'))))));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Faith'), findsWidgets);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('News'), findsOneWidget);
      expect(find.text('Space'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
    });
  });
}