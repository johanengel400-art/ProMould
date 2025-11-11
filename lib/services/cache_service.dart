// lib/services/cache_service.dart
// In-memory caching service for performance optimization

import 'log_service.dart';

/// In-memory cache service with TTL support
class CacheService {
  static final Map<String, CachedData> _cache = {};
  static const Duration defaultTTL = Duration(minutes: 5);

  /// Get cached data by key
  static T? get<T>(String key) {
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      LogService.debug('Cache hit: $key');
      return cached.data as T;
    }
    if (cached != null) {
      LogService.debug('Cache expired: $key');
      _cache.remove(key);
    }
    return null;
  }

  /// Set cached data with optional TTL
  static void set(String key, dynamic data, {Duration? ttl}) {
    _cache[key] = CachedData(
      data,
      DateTime.now().add(ttl ?? defaultTTL),
    );
    LogService.debug('Cache set: $key (TTL: ${ttl ?? defaultTTL})');
  }

  /// Get or compute cached data
  static Future<T> getOrCompute<T>(
    String key,
    Future<T> Function() compute, {
    Duration? ttl,
  }) async {
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }

    final data = await compute();
    set(key, data, ttl: ttl);
    return data;
  }

  /// Invalidate specific cache key
  static void invalidate(String key) {
    _cache.remove(key);
    LogService.debug('Cache invalidated: $key');
  }

  /// Invalidate all keys matching pattern
  static void invalidatePattern(String pattern) {
    final keysToRemove =
        _cache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    LogService.debug(
        'Cache invalidated pattern: $pattern (${keysToRemove.length} keys)');
  }

  /// Clear all cache
  static void clear() {
    final count = _cache.length;
    _cache.clear();
    LogService.info('Cache cleared ($count items)');
  }

  /// Get cache size
  static int get size => _cache.length;

  /// Get cache statistics
  static Map<String, dynamic> getStats() {
    final expired = _cache.values.where((c) => c.isExpired).length;
    final active = _cache.length - expired;

    return {
      'total': _cache.length,
      'active': active,
      'expired': expired,
      'keys': _cache.keys.toList(),
    };
  }

  /// Clean up expired entries
  static void cleanup() {
    final before = _cache.length;
    _cache.removeWhere((key, value) => value.isExpired);
    final removed = before - _cache.length;
    if (removed > 0) {
      LogService.debug('Cache cleanup: removed $removed expired entries');
    }
  }
}

/// Cached data with expiration
class CachedData {
  final dynamic data;
  final DateTime expiresAt;

  CachedData(this.data, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeToLive {
    final ttl = expiresAt.difference(DateTime.now());
    return ttl.isNegative ? Duration.zero : ttl;
  }
}

/// Cache keys constants
class CacheKeys {
  // Machines
  static const String machines = 'machines_list';
  static String machineById(String id) => 'machine_$id';
  static String machinesByFloor(String floorId) => 'machines_floor_$floorId';

  // Jobs
  static const String jobs = 'jobs_list';
  static String jobById(String id) => 'job_$id';
  static String jobsByMachine(String machineId) => 'jobs_machine_$machineId';
  static String runningJobs = 'jobs_running';

  // Moulds
  static const String moulds = 'moulds_list';
  static String mouldById(String id) => 'mould_$id';

  // Analytics
  static String oee(String machineId, String date) => 'oee_${machineId}_$date';
  static String scrapRate(String machineId, String date) =>
      'scrap_${machineId}_$date';
  static String downtime(String machineId, String date) =>
      'downtime_${machineId}_$date';

  // Dashboard
  static const String dashboardStats = 'dashboard_stats';
  static const String productionSummary = 'production_summary';
}
