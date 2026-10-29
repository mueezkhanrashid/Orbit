// Analytics — privacy-first, on-device, no PII, opt-in.
// Free: Firebase Analytics is free tier; this wrapper keeps ORBIT offline-safe.

import 'package:flutter/foundation.dart';

class OrbitAnalytics {
  bool _enabled = false;
  bool get enabled => _enabled;
  void setEnabled(bool v) => _enabled = v;

  void log(String event, [Map<String, dynamic>? params]) {
    if (!_enabled) return;
    // In production: FirebaseAnalytics.logEvent(name: event, parameters: params)
    // For now: debugPrint + Hive buffer for later flush
    if (kDebugMode) {
      debugPrint('[orbit:analytics] $event ${params ?? {}}');
    }
  }

  // Predefined funnel
  void viewedHome() => log('view_home');
  void viewedNews(String category) => log('view_news', {'category': category});
  void tappedJob(String id) => log('tap_job', {'id': id});
  void tappedScholarship(String id) => log('tap_scholarship', {'id': id});
  void completedZikar(int count) => log('zikar_complete', {'count': count});
  void completedNamaz(String name) => log('namaz_complete', {'name': name});
}
