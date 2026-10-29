// Failures — typed, user-facing, no stack-trace in UI.
sealed class OrbitFailure {
  final String message; const OrbitFailure(this.message);
}
class NetworkFailure extends OrbitFailure {
  const NetworkFailure(super.message);
}
class CacheFailure extends OrbitFailure {
  const CacheFailure(super.message);
}
class NotFoundFailure extends OrbitFailure {
  const NotFoundFailure(super.message);
}
class RateLimitFailure extends OrbitFailure {
  const RateLimitFailure(super.message);
}

// Maps DioException  OrbitFailure with retry hint.
class FailureMapper {
  static OrbitFailure from(dynamic e) {
    final s = e.toString().toLowerCase();
    if (s.contains('socket') || s.contains('connection') || s.contains('timeout')) {
      return const NetworkFailure('Showing cached');
    }
    if (s.contains('429')) return const RateLimitFailure('Too many requests — retry in 15m');
    if (s.contains('404')) return const NotFoundFailure('Not found');
    return OrbitFailureMapperGeneric(e.toString());
  }
}
class OrbitFailureMapperGeneric extends OrbitFailure {
  const OrbitFailureMapperGeneric(super.message);
}
