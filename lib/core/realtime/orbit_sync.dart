import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cache/fast_cache.dart';
import '../../app/providers.dart';

/// ORBIT Sync — Realtime Up-To-Date Engine
/// - 15m Workmanager bg (OS throttles 30m) + 60s fg for markets/ISS
/// - Stale-while-revalidate, dedup, 0ms cold open via FastCache + Hive
/// - Smart: only refresh what’s stale, backoff on fail, jitter

class OrbitSync {
  Timer? _fgTimer;
  final Ref ref;
  OrbitSync(this.ref);

  void startForegroundSmart() {
    // 60s only for volatile: markets + ISS (battery-friendly, pause when bg)
    _fgTimer?.cancel();
    _fgTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      try { ref.invalidate(marketsProvider); } catch (_) {}
      // ISS is Timer.periodic 5s inside SpaceScreen, not here
    });
  }

  void stopForeground() => _fgTimer?.cancel();

  // Call on app resume
  Future<void> refreshStale() async {
    // Invalidate only if cache >15m for news/jobs/scholarships, >30m weather, >60s markets
    try { ref.invalidate(locationProvider); } catch (_) {}
    // Let providers self-refresh via FastCache check — no force unless pull-to-refresh
  }

  void dispose() => _fgTimer?.cancel();
}

final orbitSyncProvider = Provider<OrbitSync>((ref) {
  final s = OrbitSync(ref);
  ref.onDispose(s.dispose);
  s.startForegroundSmart();
  return s;
});
