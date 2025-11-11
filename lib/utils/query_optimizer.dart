// lib/utils/query_optimizer.dart
// Database query optimization utilities

import 'package:hive/hive.dart';
import '../services/cache_service.dart';
import '../services/log_service.dart';

/// Query optimization utilities for Hive
class QueryOptimizer {
  /// Get paginated data from Hive box
  static Future<List<Map>> getPaginated({
    required Box box,
    required int page,
    required int pageSize,
    bool Function(Map)? filter,
    int Function(Map, Map)? sort,
  }) async {
    final startTime = DateTime.now();

    // Get all items
    var items = box.values.cast<Map>().toList();

    // Apply filter if provided
    if (filter != null) {
      items = items.where(filter).toList();
    }

    // Apply sort if provided
    if (sort != null) {
      items.sort(sort);
    }

    // Calculate pagination
    final start = page * pageSize;
    final end = start + pageSize;

    // Get page slice
    final result = items.sublist(
      start.clamp(0, items.length),
      end.clamp(0, items.length),
    );

    final duration = DateTime.now().difference(startTime);
    LogService.performance('Query paginated', duration);

    return result;
  }

  /// Get cached or fetch data
  static Future<List<Map>> getCachedList({
    required String cacheKey,
    required Box box,
    bool Function(Map)? filter,
    Duration cacheTTL = const Duration(minutes: 5),
  }) async {
    return await CacheService.getOrCompute<List<Map>>(
      cacheKey,
      () async {
        var items = box.values.cast<Map>().toList();
        if (filter != null) {
          items = items.where(filter).toList();
        }
        return items;
      },
      ttl: cacheTTL,
    );
  }

  /// Get single item with caching
  static Future<Map?> getCachedItem({
    required String cacheKey,
    required Box box,
    required String id,
    Duration cacheTTL = const Duration(minutes: 10),
  }) async {
    return await CacheService.getOrCompute<Map?>(
      cacheKey,
      () async {
        final item = box.get(id);
        return item is Map ? item : null;
      },
      ttl: cacheTTL,
    );
  }

  /// Batch get items
  static List<Map> batchGet(Box box, List<String> ids) {
    final startTime = DateTime.now();

    final results = <Map>[];
    for (final id in ids) {
      final item = box.get(id);
      if (item is Map) {
        results.add(item);
      }
    }

    final duration = DateTime.now().difference(startTime);
    LogService.performance('Batch get ${ids.length} items', duration);

    return results;
  }

  /// Batch put items
  static Future<void> batchPut(Box box, Map<String, Map> items) async {
    final startTime = DateTime.now();

    await box.putAll(items);

    final duration = DateTime.now().difference(startTime);
    LogService.performance('Batch put ${items.length} items', duration);
  }

  /// Count items matching filter
  static int count(Box box, bool Function(Map) filter) {
    return box.values.cast<Map>().where(filter).length;
  }

  /// Check if any item matches filter
  static bool any(Box box, bool Function(Map) filter) {
    return box.values.cast<Map>().any(filter);
  }

  /// Find first item matching filter
  static Map? findFirst(Box box, bool Function(Map) filter) {
    try {
      return box.values.cast<Map>().firstWhere(filter);
    } catch (e) {
      return null;
    }
  }

  /// Group items by key
  static Map<String, List<Map>> groupBy(
    Box box,
    String Function(Map) keySelector,
  ) {
    final groups = <String, List<Map>>{};

    for (final item in box.values.cast<Map>()) {
      final key = keySelector(item);
      groups.putIfAbsent(key, () => []).add(item);
    }

    return groups;
  }

  /// Get distinct values for a field
  static List<dynamic> distinct(Box box, String field) {
    final values = <dynamic>{};

    for (final item in box.values.cast<Map>()) {
      if (item.containsKey(field)) {
        values.add(item[field]);
      }
    }

    return values.toList();
  }

  /// Aggregate sum
  static num sum(Box box, num Function(Map) selector) {
    return box.values.cast<Map>().fold<num>(
          0,
          (sum, item) => sum + selector(item),
        );
  }

  /// Aggregate average
  static double average(Box box, num Function(Map) selector) {
    final items = box.values.cast<Map>().toList();
    if (items.isEmpty) return 0.0;

    final total = items.fold<num>(0, (sum, item) => sum + selector(item));
    return total / items.length;
  }

  /// Get min value
  static num? min(Box box, num Function(Map) selector) {
    final items = box.values.cast<Map>().toList();
    if (items.isEmpty) return null;

    return items.map(selector).reduce((a, b) => a < b ? a : b);
  }

  /// Get max value
  static num? max(Box box, num Function(Map) selector) {
    final items = box.values.cast<Map>().toList();
    if (items.isEmpty) return null;

    return items.map(selector).reduce((a, b) => a > b ? a : b);
  }
}

/// Common query filters
class QueryFilters {
  /// Filter by status
  static bool Function(Map) byStatus(String status) {
    return (item) => item['status'] == status;
  }

  /// Filter by date range
  static bool Function(Map) byDateRange(
    String dateField,
    DateTime start,
    DateTime end,
  ) {
    return (item) {
      final dateStr = item[dateField] as String?;
      if (dateStr == null) return false;

      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;

      return date.isAfter(start) && date.isBefore(end);
    };
  }

  /// Filter by machine ID
  static bool Function(Map) byMachineId(String machineId) {
    return (item) => item['machineId'] == machineId;
  }

  /// Filter by floor ID
  static bool Function(Map) byFloorId(String floorId) {
    return (item) => item['floorId'] == floorId;
  }

  /// Combine multiple filters with AND
  static bool Function(Map) and(List<bool Function(Map)> filters) {
    return (item) => filters.every((filter) => filter(item));
  }

  /// Combine multiple filters with OR
  static bool Function(Map) or(List<bool Function(Map)> filters) {
    return (item) => filters.any((filter) => filter(item));
  }
}

/// Common sort comparators
class QuerySorters {
  /// Sort by field ascending
  static int Function(Map, Map) byFieldAsc(String field) {
    return (a, b) {
      final aVal = a[field];
      final bVal = b[field];
      if (aVal == null && bVal == null) return 0;
      if (aVal == null) return 1;
      if (bVal == null) return -1;
      return Comparable.compare(aVal as Comparable, bVal as Comparable);
    };
  }

  /// Sort by field descending
  static int Function(Map, Map) byFieldDesc(String field) {
    return (a, b) {
      final aVal = a[field];
      final bVal = b[field];
      if (aVal == null && bVal == null) return 0;
      if (aVal == null) return -1;
      if (bVal == null) return 1;
      return Comparable.compare(bVal as Comparable, aVal as Comparable);
    };
  }

  /// Sort by date field descending (most recent first)
  static int Function(Map, Map) byDateDesc(String field) {
    return (a, b) {
      final aDate = DateTime.tryParse(a[field] ?? '');
      final bDate = DateTime.tryParse(b[field] ?? '');
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    };
  }
}
