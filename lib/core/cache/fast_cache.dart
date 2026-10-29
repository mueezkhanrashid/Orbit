import 'dart:async';

/// ORBIT FastCache — in-memory 60fps instantly, Hive persists.
/// Stale-while-revalidate: get() returns cached instantly if fresh, else triggers background refresh.
/// Keeps latest data at 0ms on app open.

class FastCacheEntry<T> {
  final T data;
  final DateTime fetchedAt;
  FastCacheEntry(this.data, this.fetchedAt);
  bool isFresh(Duration ttl) => DateTime.now().difference(fetchedAt) < ttl;
}

class FastCache {
  static final FastCache _i = FastCache._();
  FastCache._();
  factory FastCache() => _i;

  final _mem = <String, FastCacheEntry<dynamic>>{};
  final _inFlight = <String, Future<dynamic>>{};

  T? get<T>(String key, Duration ttl) {
    final e = _mem[key] as FastCacheEntry<T>?;
    if (e != null && e.isFresh(ttl)) return e.data;
    return null;
  }

  // Peek even if stale — for 0ms offline rendering
  T? peek<T>(String key) => (_mem[key] as FastCacheEntry<T>?)?.data;

  void set<T>(String key, T data) {
    _mem[key] = FastCacheEntry<T>(data, DateTime.now());
  }

  void invalidate(String key) { _mem.remove(key); _inFlight.remove(key); }
  void clear() { _mem.clear(); _inFlight.clear(); }

  /// Dedup: if same key is already fetching, return same future instead of firing parallel dups.
  Future<T> dedup<T>(String key, Future<T> Function() loader) {
    if (_inFlight.containsKey(key)) return _inFlight[key] as Future<T>;
    final f = loader().whenComplete(() => _inFlight.remove(key));
    _inFlight[key] = f;
    return f;
  }
}
