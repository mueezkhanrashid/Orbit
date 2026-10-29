// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit/core/test_flag.dart';
import 'package:orbit/theme/app_theme.dart';
import 'package:orbit/core/utils/constants.dart';
import 'package:orbit/core/security/security_service.dart';
import 'package:orbit/core/smart/profile_store.dart';
import 'package:orbit/core/ai/advanced_ai_engine.dart';
import 'package:orbit/core/location/location_service.dart';

void main(){
  setUpAll(() async {
    try {
      orbitIsTest = true;
      Directory? dir;
      try { dir = await Directory.systemTemp.createTemp('hive_test_orbit_'); } catch (_) { dir = Directory('/tmp/hive_test_orbit'); try { if(!await dir.exists()) await dir.create(recursive:true); } catch(_){} }
      try { Hive.init(dir.path); } catch(_){}
      for (final name in ['orbit_prefs','orbit_security','orbit_jobs','orbit_news','orbit_weather','orbit_markets','orbit_scholarships','orbit_prayers','orbit_quran','orbit_zikar','orbit_notebook','orbit_space']) {
        try { if (!Hive.isBoxOpen(name)) await Hive.openBox(name); } catch(_ ){}
      }
    } catch (e) { print('verified setUpAll suppressed: $e'); }
  });
  tearDownAll(() async {
    /* keep Hive open for next suite */
  });
  group('ORBIT Verified — Zara QA', (){
    test('Theme tokens Google-calm', (){
      // Editorial greeting — taste-skill v2: primary near-black, radius soft 12, no shadow on resting cards
      expect(OrbitTheme.primary, const Color(0xFF1F201D));
      expect(OrbitTheme.accent, const Color(0xFF1B6E66));
      expect(OrbitTheme.rCard, 12);
      expect(OrbitTheme.cardShadow.length, 0);
      expect(OrbitTheme.ground, const Color(0xFFFFFFFF));
    });
    test('Constants Pakistan-first', (){
      expect(OrbitConstants.cityName, 'Rawalpindi');
      expect(OrbitConstants.zikarGoal, 33);
      expect(OrbitConstants.cacheTtlNews.inMinutes, 15);
      expect(OrbitConstants.cacheTtlMarkets.inMinutes, 1);
    });
    test('Security audit', (){
      final svc = SecurityService();
      final audit = svc.audit();
      expect(audit['sslPinned'], true);
      expect(audit['score'], greaterThanOrEqualTo(20));
    });
    test('ProfileStore history', (){
      final store = ProfileStore();
      store.addHistory('tap:job:flutter');
      expect(store.history().first, contains('flutter'));
      expect(store.learnedKeywords(), contains('flutter'));
    });
    test('Advanced AI cosine', (){
      final engine = AdvancedAiEngine();
      final corpus=['flutter lahore','erasmus mundus'];
      final score = engine.advancedScore(title:'Flutter Developer Lahore', org:'Careem', location:'Lahore', userLoc: OrbitLocation.rawalpindi(), category:'job', due:'2h ago', corpusTitles: corpus);
      expect(score, greaterThan(50));
    });
    test('Location fallback', (){
      final loc = OrbitLocation.rawalpindi();
      expect(loc.city, 'Rawalpindi');
      expect(loc.countryCode, 'PK');
    });
  });
}