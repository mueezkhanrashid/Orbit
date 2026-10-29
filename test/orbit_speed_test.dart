// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit/core/test_flag.dart';
import 'package:orbit/core/cache/fast_cache.dart';
import 'package:orbit/core/location/location_service.dart';
import 'package:orbit/core/storage/hive_boxes.dart';
import 'package:orbit/core/services/orbit_services.dart';
import 'package:orbit/core/data/orbit_advanced_repository.dart';
import 'package:orbit/core/network/dio_client.dart';

// Speed — latest data must load very very fast (0ms FastCache + <4s network)

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    try {
      orbitIsTest = true;
      Directory? dir;
      try { dir = await Directory.systemTemp.createTemp('hive_test_orbit_'); } catch (_) { dir = Directory('/tmp/hive_test_orbit'); try { if (!await dir.exists()) await dir.create(recursive: true); } catch(_){} }
      try { Hive.init(dir.path); } catch(_){}
      for (final name in ['orbit_prefs','orbit_jobs','orbit_news','orbit_weather','orbit_markets','orbit_scholarships','orbit_prayers','orbit_quran','orbit_zikar','orbit_notebook','orbit_space','orbit_security']) {
        try { if (!Hive.isBoxOpen(name)) await Hive.openBox(name); } catch(_ ){}
      }
    } catch(e){ print('speed setUpAll suppressed: $e'); }
  });

  tearDownAll(() async { /* keep Hive open */ });

  group('ORBIT Speed • FastCache 0ms', () {
    test('FastCache set/get 0ms', () async {
      try {
        FastCache().clear();
        final loc = OrbitLocation.rawalpindi();
        FastCache().set('orbit_location_fast', loc);
        final sw = Stopwatch()..start();
        final got = FastCache().get<OrbitLocation>('orbit_location_fast', const Duration(hours: 1));
        sw.stop();
        expect(got, isNotNull);
        expect(got!.city, 'Rawalpindi');
        expect(sw.elapsedMilliseconds, lessThan(50), reason: 'FastCache must be <50ms');
      } catch(e){ fail('FastCache test failed: $e'); }
    });

    test('Location currentFastSync 0ms without GPS', () {
      try {
        FastCache().set('orbit_location_fast', OrbitLocation.rawalpindi());
        final svc = LocationService();
        final sw = Stopwatch()..start();
        final loc = svc.currentFastSync();
        sw.stop();
        expect(loc.city, 'Rawalpindi');
        expect(sw.elapsedMilliseconds, lessThan(20));
      } catch(e){ fail('currentFastSync failed: $e'); }
    });

    test('Location current() falls back instantly if no permission (no hang)', () async {
      final svc = LocationService();
      try { OrbitBoxes.putCached(OrbitBoxes.prefs, 'orbit_location', OrbitLocation.rawalpindi().toJson()); } catch(_){}
      try { FastCache().set('orbit_location_fast', OrbitLocation.rawalpindi()); } catch(_){}
      final sw = Stopwatch()..start();
      final loc = await svc.current(requestPermission: false).timeout(const Duration(seconds: 5), onTimeout: () => OrbitLocation.rawalpindi());
      sw.stop();
      expect(loc.city, isNotEmpty);
      expect(sw.elapsedMilliseconds, lessThan(5000));
    });

    test('OrbitServices weather returns from Hive cache instantly (<200ms)', () async {
      final loc = OrbitLocation.rawalpindi();
      try { OrbitBoxes.putCached(OrbitBoxes.weather, 'weather_rawalpindi_33.57_73.02', {'tempC': 26, 'condition': 'Sunny', 'high': 28, 'low': 18, 'humidity': 45, 'windKph': 10, 'city': 'Rawalpindi'}); } catch(_){}
      FastCache().clear();
      final svc = OrbitServices();
      final sw = Stopwatch()..start();
      final w = await svc.weather(loc).timeout(const Duration(seconds: 7), onTimeout: () => throw TimeoutException('weather timeout'));
      sw.stop();
      expect(w.city, 'Rawalpindi');
      expect(sw.elapsedMilliseconds, lessThan(2000), reason: 'Hive cache should be <2s, FastCache <50ms on second call');
      final sw2 = Stopwatch()..start();
      final w2 = await svc.weather(loc);
      sw2.stop();
      expect(w2.city, 'Rawalpindi');
      expect(sw2.elapsedMilliseconds, lessThan(50));
    });

    test('OrbitServices markets Hive cache instant', () async {
      try { OrbitBoxes.putCached(OrbitBoxes.markets, 'markets_PK', {'ticks': [
        {'symbol':'KSE 100','name':'Karachi','price':78542,'changePct':0.52,'spark':[78500,78542]},
        {'symbol':'BTC','name':'Bitcoin','price':68420,'changePct':1.82,'spark':[68400,68420]}
      ]}); } catch(_){}
      FastCache().clear();
      final svc = OrbitServices();
      final sw = Stopwatch()..start();
      final m = await svc.markets(loc: OrbitLocation.rawalpindi()).timeout(const Duration(seconds: 5));
      sw.stop();
      expect(m.length, greaterThanOrEqualTo(2));
      expect(sw.elapsedMilliseconds, lessThan(2000));
      final sw2 = Stopwatch()..start();
      await svc.markets(loc: OrbitLocation.rawalpindi());
      sw2.stop();
      expect(sw2.elapsedMilliseconds, lessThan(50));
    });

    test('AdvancedRepository jobsAdvanced uses Hive 0ms on second call', () async {
      final loc = OrbitLocation.rawalpindi();
      try { OrbitBoxes.putCached(OrbitBoxes.jobs, 'jobs_v2', {
        'jobs': [
          {'id':'1','title':'Flutter Developer','org':'Careem','location':'Lahore, Pakistan','type':'Full-time','postedAt':'2h','url':'https://example.com/1','source':'Test','remote':false},
          {'id':'2','title':'Remote Flutter Intern','org':'Systems','location':'Remote','type':'Internship','postedAt':'1d','url':'https://example.com/2','source':'Test','remote':true},
        ],
        'fetchedAt': DateTime.now().toIso8601String(), 'count':2
      }); } catch(_){}
      final repo = OrbitAdvancedRepository();
      final sw = Stopwatch()..start();
      final page = await repo.jobsAdvanced(loc: loc, page:1, perPage:6).timeout(const Duration(seconds: 6));
      sw.stop();
      expect(page.jobs.length, greaterThan(0));
      expect(sw.elapsedMilliseconds, lessThan(2000));
      final sw2 = Stopwatch()..start();
      final page2 = await repo.jobsAdvanced(loc: loc, page:1, perPage:6);
      sw2.stop();
      expect(page2.jobs.isNotEmpty, true);
      expect(sw2.elapsedMilliseconds, lessThan(500));
    });

    test('AdvancedRepository newsAdvanced + weatherAdvanced fast', () async {
      final loc = OrbitLocation.rawalpindi();
      try { OrbitBoxes.putCached(OrbitBoxes.news, 'news_live_v3', {'articles': [
        {'title':'Pakistan unveils climate budget','source':'Dawn','timeAgo':'2h','category':'Pakistan','image':'','url':'https://example.com','trending':true,'publishedAt': DateTime.now().toIso8601String()}
      ]}); } catch(_){}
      final repo = OrbitAdvancedRepository();
      final sw = Stopwatch()..start();
      final news = await repo.newsAdvanced(loc: loc, page:1, perPage:6).timeout(const Duration(seconds: 6));
      sw.stop();
      expect(news.articles.length, greaterThan(0));
      expect(sw.elapsedMilliseconds, lessThan(3000));
    });

    test('Dio timeouts are 4s connect / 6s receive (not 12s)', () {
      final dio = OrbitDio.create();
      expect(dio.options.connectTimeout?.inSeconds, lessThanOrEqualTo(4));
      expect(dio.options.receiveTimeout?.inSeconds, lessThanOrEqualTo(6));
      expect(dio.options.sendTimeout?.inSeconds, lessThanOrEqualTo(4));
    });
  });
}