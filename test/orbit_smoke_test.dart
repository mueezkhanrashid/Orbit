import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/theme/app_theme.dart';
import 'package:orbit/core/utils/constants.dart';

// Smoke — no device, no keys, runs in CI in 2s.
void main(){
  group('Orbit smoke', (){
    test('tokens are Google-calm', (){
      // Taste editorial-greeting: near-black primary, teal accent, 12 radius, no shadow
      expect(OrbitTheme.primary, const Color(0xFF1F201D));
      expect(OrbitTheme.accent, const Color(0xFF1B6E66));
      expect(OrbitTheme.rCard, 12);
    });
    test('constants are Pakistan-first', (){
      expect(OrbitConstants.cityName, 'Rawalpindi');
      expect(OrbitConstants.cityLat, closeTo(33.56, 0.01));
      expect(OrbitConstants.zikarGoal, 33);
    });
    test('cache TTLs honor free tier', (){
      expect(OrbitConstants.cacheTtlNews.inMinutes, 15);
      expect(OrbitConstants.cacheTtlWeather.inMinutes, 30);
      expect(OrbitConstants.cacheTtlMarkets.inMinutes, 1);
      expect(OrbitConstants.cacheTtlJobs.inHours, 6);
    });
  });
}
