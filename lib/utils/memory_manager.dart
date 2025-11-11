// lib/utils/memory_manager.dart
// Memory management utilities

import 'package:flutter/material.dart';
import '../services/log_service.dart';
import '../services/cache_service.dart';

/// Memory management utilities for optimization
class MemoryManager {
  static bool _initialized = false;

  /// Initialize memory management
  static void initialize() {
    if (_initialized) return;

    limitCacheSize();
    _initialized = true;
    LogService.info('MemoryManager initialized');
  }

  /// Clear image cache
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    LogService.info('Image cache cleared');
  }

  /// Limit image cache size
  static void limitCacheSize({int maxSize = 100, int maxSizeBytes = 50 << 20}) {
    PaintingBinding.instance.imageCache.maximumSize = maxSize;
    PaintingBinding.instance.imageCache.maximumSizeBytes = maxSizeBytes;
    LogService.debug(
        'Image cache limited: $maxSize images, ${maxSizeBytes ~/ (1 << 20)}MB');
  }

  /// Get current memory usage statistics
  static Map<String, dynamic> getStats() {
    final imageCache = PaintingBinding.instance.imageCache;

    return {
      'imageCacheSize': imageCache.currentSize,
      'imageCacheMaxSize': imageCache.maximumSize,
      'imageCacheSizeBytes': imageCache.currentSizeBytes,
      'imageCacheMaxSizeBytes': imageCache.maximumSizeBytes,
      'dataCacheSize': CacheService.size,
    };
  }

  /// Perform aggressive memory cleanup
  static void aggressiveCleanup() {
    LogService.info('Performing aggressive memory cleanup...');

    // Clear image cache
    clearImageCache();

    // Clear data cache
    CacheService.clear();

    // Force garbage collection (hint to VM)
    // Note: This is just a hint, actual GC is controlled by the VM

    LogService.info('Aggressive cleanup complete');
  }

  /// Perform light memory cleanup
  static void lightCleanup() {
    LogService.debug('Performing light memory cleanup...');

    // Clean up expired cache entries
    CacheService.cleanup();

    // Trim image cache if over 80% capacity
    final imageCache = PaintingBinding.instance.imageCache;
    if (imageCache.currentSize > imageCache.maximumSize * 0.8) {
      imageCache.clear();
      LogService.debug('Image cache trimmed');
    }
  }

  /// Log current memory statistics
  static void logStats() {
    final stats = getStats();
    LogService.info('Memory Stats: '
        'Images: ${stats['imageCacheSize']}/${stats['imageCacheMaxSize']}, '
        'Data Cache: ${stats['dataCacheSize']} items');
  }

  /// Check if memory usage is high
  static bool isMemoryHigh() {
    final imageCache = PaintingBinding.instance.imageCache;
    return imageCache.currentSize > imageCache.maximumSize * 0.9 ||
        imageCache.currentSizeBytes > imageCache.maximumSizeBytes * 0.9;
  }

  /// Auto cleanup if memory is high
  static void autoCleanup() {
    if (isMemoryHigh()) {
      LogService.warning('High memory usage detected, performing cleanup');
      lightCleanup();
    }
  }
}

/// Mixin for automatic memory management in StatefulWidgets
mixin MemoryManagementMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    MemoryManager.autoCleanup();
  }

  @override
  void dispose() {
    // Cleanup can be called here if needed
    super.dispose();
  }
}
