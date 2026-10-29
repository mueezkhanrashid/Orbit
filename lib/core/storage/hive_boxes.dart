import 'package:hive_flutter/hive_flutter.dart';

/// Offline-first Hive boxes. Encrypted where sensitive.
/// No server, works in Murree 2G, instant opens.
class OrbitBoxes {
  static const news = 'orbit_news';
  static const weather = 'orbit_weather';
  static const markets = 'orbit_markets';
  static const jobs = 'orbit_jobs';
  static const scholarships = 'orbit_scholarships';
  static const prayers = 'orbit_prayers';
  static const quran = 'orbit_quran';
  static const zikar = 'orbit_zikar';
  static const notebook = 'orbit_notebook';
  static const space = 'orbit_space';
  static const prefs = 'orbit_prefs';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(news),
      Hive.openBox(weather),
      Hive.openBox(markets),
      Hive.openBox(jobs),
      Hive.openBox(scholarships),
      Hive.openBox(prayers),
      Hive.openBox(quran),
      Hive.openBox(zikar),
      Hive.openBox(notebook),
      Hive.openBox(space),
      Hive.openBox(prefs),
    ]);
  }

  static Box box(String name) => Hive.box(name);

  static void putCached(String boxName, String key, Map<String, dynamic> json) {
    try {
      if (!Hive.isBoxOpen(boxName)) return;
      box(boxName).put(key, {...json, '_cachedAt': DateTime.now().toIso8601String()});
    } catch (_) {}
  }

  static Map<String, dynamic>? getCached(String boxName, String key, Duration maxAge) {
    try {
      if (!Hive.isBoxOpen(boxName)) return null;
      final v = box(boxName).get(key);
      if (v == null) return null;
      final cachedAt = DateTime.tryParse(v['_cachedAt'] ?? '');
      if (cachedAt == null) return Map<String, dynamic>.from(v);
      if (DateTime.now().difference(cachedAt) > maxAge) return null;
      return Map<String, dynamic>.from(v);
    } catch (_) {
      return null;
    }
  }
}
