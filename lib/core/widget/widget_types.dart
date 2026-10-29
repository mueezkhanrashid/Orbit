// ORBIT Widget — swipeable 4x2 stack, user picks cards
// Modern icons: Material 3 rounded, no emojis/glyphs — flat 1px, tabular, honest zero

import 'package:flutter/material.dart';
import 'dart:math' as math;

enum OrbitWidgetType {
  namaz('Namaz', 'Prayer times • Rawalpindi', Icons.mosque_rounded, 'namaz'),
  qibla('Qibla', 'Kaaba bearing • Live compass', Icons.explore_rounded, 'qibla'),
  space('Space', 'ISS • Live', Icons.satellite_alt_rounded, 'space'),
  news('News', 'For you • Auto PK', Icons.newspaper_rounded, 'news'),
  jobs('Jobs', 'Near you • 3,800', Icons.work_rounded, 'jobs'),
  weather('Weather', 'Rawalpindi • 26° Sunny', Icons.wb_sunny_rounded, 'weather'),
  markets('Markets', 'KSE 100 • BTC • 60s', Icons.show_chart_rounded, 'markets'),
  quran('Quran', 'Ayah 65:2 • Way out', Icons.menu_book_rounded, 'quran'),
  scholarships('Scholarships', 'For Pakistani • 24', Icons.school_rounded, 'scholarships'),
  internships('Internships', 'Remote • 42', Icons.laptop_mac_rounded, 'internships'),
  zikar('Zikar', '33 • Alhamdulillah', Icons.favorite_rounded, 'zikar');

  const OrbitWidgetType(this.label, this.subtitle, this.icon, this.assetKey);
  final String label;
  final String subtitle;
  final IconData icon;
  final String assetKey; // maps to assets/icons/<key>.svg + android drawable ic_<key>

  /// Legacy glyph for migration (no longer used in UI) — kept for Hive decode
  String get glyph {
    switch (this) {
      case OrbitWidgetType.namaz: return 'namaz';
      case OrbitWidgetType.qibla: return 'qibla';
      case OrbitWidgetType.space: return 'space';
      case OrbitWidgetType.news: return 'news';
      case OrbitWidgetType.jobs: return 'jobs';
      case OrbitWidgetType.weather: return 'weather';
      case OrbitWidgetType.markets: return 'markets';
      case OrbitWidgetType.quran: return 'quran';
      case OrbitWidgetType.scholarships: return 'scholarships';
      case OrbitWidgetType.internships: return 'internships';
      case OrbitWidgetType.zikar: return 'zikar';
    }
  }

  String get svgAsset => 'assets/icons/$assetKey.svg';

  static OrbitWidgetType fromKey(String k) =>
      values.firstWhere((e) => e.name == k, orElse: () => OrbitWidgetType.namaz);
}

// Qibla math — Kaaba 21.4225, 39.8262
class QiblaMath {
  static const kaabaLat = 21.4225;
  static const kaabaLng = 39.8262;

  static double bearing(double lat, double lng) {
    final p1 = lat * math.pi / 180;
    final l1 = lng * math.pi / 180;
    const p2 = kaabaLat * math.pi / 180;
    const l2 = kaabaLng * math.pi / 180;
    final dLng = l2 - l1;
    final y = math.sin(dLng) * math.cos(p2);
    final x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dLng);
    var brng = math.atan2(y, x) * 180 / math.pi;
    brng = (brng + 360) % 360;
    return brng;
  }

  static String direction(double brng) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((brng + 22.5) / 45).floor() % 8;
    return dirs[idx];
  }

  static double distanceKm(double lat, double lng) {
    const R = 6371.0;
    final dLat = (kaabaLat - lat) * math.pi / 180;
    final dLng = (kaabaLng - lng) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat * math.pi / 180) * math.cos(kaabaLat * math.pi / 180) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static String bearingLabel(double lat, double lng) {
    final b = bearing(lat, lng);
    final d = direction(b);
    return '${b.toStringAsFixed(0)}° $d';
  }

  // Modern: UI uses Icons.navigation_rounded rotated via rotationForBearing; arrow string kept for compat returns direction
  static String arrowForBearing(double brng) => direction(brng);

  /// Modern icon rotation for bearing (0° = north)
  static double rotationForBearing(double brng) => (brng * math.pi / 180);
}

// Card data shown in widget — well presented, up-to-date
class OrbitWidgetCard {
  final OrbitWidgetType type;
  final String title;
  final String subtitle;
  final String meta;
  final String value;
  final DateTime updatedAt;
  final bool isStale;
  final double? bearing;
  final String? bearingLabel;
  final String? arrow;

  const OrbitWidgetCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.value,
    required this.updatedAt,
    this.isStale = false,
    this.bearing,
    this.bearingLabel,
    this.arrow,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'subtitle': subtitle,
        'meta': meta,
        'value': value,
        'updatedAt': updatedAt.toIso8601String(),
        'isStale': isStale,
        if (bearing != null) 'bearing': bearing,
        if (bearingLabel != null) 'bearingLabel': bearingLabel,
        if (arrow != null) 'arrow': arrow,
      };

  factory OrbitWidgetCard.fromJson(Map<String, dynamic> j) => OrbitWidgetCard(
        type: OrbitWidgetType.fromKey(j['type']),
        title: j['title'],
        subtitle: j['subtitle'],
        meta: j['meta'] ?? '',
        value: j['value'] ?? '',
        updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
        isStale: j['isStale'] ?? false,
        bearing: (j['bearing'] as num?)?.toDouble(),
        bearingLabel: j['bearingLabel'],
        arrow: j['arrow'],
      );
}

// Default 6 per user pick: medium_only 4x2 swipeable — includes Qibla navigator second
const kDefaultWidgetOrder = [
  OrbitWidgetType.namaz,
  OrbitWidgetType.qibla,
  OrbitWidgetType.space,
  OrbitWidgetType.news,
  OrbitWidgetType.jobs,
  OrbitWidgetType.weather,
];
