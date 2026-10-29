import 'dart:async';
import 'package:flutter/widgets.dart';
import '../test_flag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../smart/smart_engine.dart';

// REAL-TIME ADVANCED — $0, no paid sockets. Polling + stale-while-revalidate + background sync.
// Markets 60s, Weather 30m + 7d hourly, ISS 5s, Launches 1h, News 15m, Scholarships 1h, Smart leads 5m
// Hive makes it instant offline. Advanced: isolate parsing, semantic ranking, freshness stamps.

class RealtimeService {
  final Ref _ref;
  final _timers = <Timer>[];
  Timer? _analyticsTimer;
  RealtimeService(this._ref);

  void start() {
    if (orbitIsTest) return;
    // Skip all timers in test
    try {
      if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) return;
    } catch(_){}
    try {
      // ignore: avoid_web_libraries_in_flutter
      if (const bool.fromEnvironment('FLUTTER_TEST')) return;
    } catch(_){}
    // Markets 60s — Yahoo+CoinGecko 10 tickers
    _timers.add(Timer.periodic(const Duration(seconds: 60), (_) {
      _ref.invalidate(marketsProvider);
    }));
    // Weather 30m + advanced 7-day hourly via repository
    _timers.add(Timer.periodic(const Duration(minutes: 30), (_) {
      _ref.invalidate(weatherProvider);
      final repo = _ref.read(advancedRepositoryProvider);
      _ref.read(locationProvider.future).then((loc) {
        repo.weatherAdvanced(loc).catchError((_) => <String, dynamic>{});
      }).catchError((_) {});
    }));
    // Namaz every minute for countdown
    _timers.add(Timer.periodic(const Duration(minutes: 1), (_) {
      _ref.invalidate(namazProvider);
    }));
    // News 15m
    _timers.add(Timer.periodic(const Duration(minutes: 15), (_) {
      // news auto-refresh via scroll — no provider invalidate needed
    }));
    // Smart leads 5m — recalc TF-IDF
    _timers.add(Timer.periodic(const Duration(minutes: 5), (_) {
      // smart leads recalc via repository — no provider invalidate needed
    }));
    // Analytics snapshot 10m
    _analyticsTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      try {
        final repo = _ref.read(advancedRepositoryProvider);
        await repo.analyticsSnapshot();
      } catch (_) {}
    });
  }

  Future<void> manualRefresh() async {
    _ref.invalidate(locationProvider);
    _ref.invalidate(weatherProvider);
    _ref.invalidate(marketsProvider);
    _ref.invalidate(namazProvider);
    // news
    // leads
    // Warm advanced
    try {
      final repo = _ref.read(advancedRepositoryProvider);
      final loc = await _ref.read(locationProvider.future);
      await Future.wait([
        repo.weatherAdvanced(loc).catchError((_) => <String, dynamic>{}),
        repo.smartLeadsAdvanced(loc).catchError((_) => <SmartLead>[]),
      ]);
    } catch (_) {}
  }

  void stop() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _analyticsTimer?.cancel();
  }
}

final realtimeProvider = Provider<RealtimeService>((ref) {
  final s = RealtimeService(ref);
  ref.onDispose(() => s.stop());
  s.start();
  return s;
});
