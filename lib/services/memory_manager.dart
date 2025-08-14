import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'performance_service.dart';

/// مدير الذاكرة المحسن
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  // كاش الذاكرة مع LRU
  final LinkedHashMap<String, CacheEntry> _memoryCache = LinkedHashMap();
  final Map<String, int> _accessCounts = {};
  final Map<String, DateTime> _lastAccess = {};
  
  // إعدادات الذاكرة
  static const int _maxMemoryItems = 50;
  static const int _maxMemorySize = 20 * 1024 * 1024; // 20 MB
  static const int _cleanupThreshold = 40; // تنظيف عند 40 عنصر
  static const Duration _itemExpiry = Duration(hours: 2);
  
  Timer? _cleanupTimer;
  int _currentMemorySize = 0;
  bool _isOptimizing = false;

  /// بدء إدارة الذاكرة
  void startManagement() {
    // تنظيف دوري كل 10 دقائق
    _cleanupTimer = Timer.periodic(Duration(minutes: 10), (_) {
      _performCleanup();
    });
    
    print('🧠 تم بدء إدارة الذاكرة');
  }

  /// إيقاف إدارة الذاكرة
  void stopManagement() {
    _cleanupTimer?.cancel();
    print('⏹️ تم إيقاف إدارة الذاكرة');
  }

  /// إضافة عنصر للكاش
  void put<T>(String key, T data, {int? sizeBytes, Duration? ttl}) {
    final size = sizeBytes ?? _estimateSize(data);
    final expiry = ttl != null ? DateTime.now().add(ttl) : DateTime.now().add(_itemExpiry);
    
    // التحقق من المساحة المتاحة
    if (_currentMemorySize + size > _maxMemorySize) {
      _freeMemorySpace(size);
    }
    
    // إضافة العنصر
    final entry = CacheEntry<T>(
      key: key,
      data: data,
      size: size,
      createdAt: DateTime.now(),
      expiresAt: expiry,
      accessCount: 1,
    );
    
    _memoryCache[key] = entry;
    _accessCounts[key] = 1;
    _lastAccess[key] = DateTime.now();
    _currentMemorySize += size;
    
    // تنظيف إذا وصلنا للحد الأقصى
    if (_memoryCache.length > _cleanupThreshold) {
      _performLRUCleanup();
    }
    
    if (kDebugMode) {
      print('💾 تم إضافة $key للكاش (${size} بايت)');
    }
  }

  /// الحصول على عنصر من الكاش
  T? get<T>(String key) {
    final entry = _memoryCache[key];
    
    if (entry == null) return null;
    
    // التحقق من انتهاء الصلاحية
    if (entry.isExpired) {
      remove(key);
      return null;
    }
    
    // تحديث إحصائيات الوصول
    _accessCounts[key] = (_accessCounts[key] ?? 0) + 1;
    _lastAccess[key] = DateTime.now();
    entry.accessCount++;
    
    // نقل للنهاية (LRU)
    _memoryCache.remove(key);
    _memoryCache[key] = entry;
    
    return entry.data as T?;
  }

  /// إزالة عنصر من الكاش
  bool remove(String key) {
    final entry = _memoryCache.remove(key);
    if (entry != null) {
      _currentMemorySize -= entry.size;
      _accessCounts.remove(key);
      _lastAccess.remove(key);
      
      if (kDebugMode) {
        print('🗑️ تم إزالة $key من الكاش');
      }
      
      return true;
    }
    return false;
  }

  /// التحقق من وجود عنصر
  bool containsKey(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return false;
    
    if (entry.isExpired) {
      remove(key);
      return false;
    }
    
    return true;
  }

  /// مسح جميع العناصر
  void clear() {
    _memoryCache.clear();
    _accessCounts.clear();
    _lastAccess.clear();
    _currentMemorySize = 0;
    
    print('🧹 تم مسح جميع عناصر الكاش');
  }

  /// تحسين الذاكرة
  Future<void> optimize() async {
    if (_isOptimizing) return;
    
    _isOptimizing = true;
    
    try {
      await PerformanceService().measureOperation('memory_optimization', () async {
        print('⚡ بدء تحسين الذاكرة...');
        
        // إزالة العناصر المنتهية الصلاحية
        _removeExpiredItems();
        
        // تنظيف LRU إذا كان الكاش ممتلئاً
        if (_memoryCache.length > _maxMemoryItems * 0.8) {
          _performLRUCleanup();
        }
        
        // ضغط البيانات إذا أمكن
        await _compressLargeItems();
        
        // إعادة تنظيم الكاش
        _reorganizeCache();
        
        print('✅ تم تحسين الذاكرة: ${_memoryCache.length} عنصر، ${_formatSize(_currentMemorySize)}');
      });
      
    } finally {
      _isOptimizing = false;
    }
  }

  /// تنظيف دوري
  void _performCleanup() {
    if (_isOptimizing) return;
    
    print('🧹 بدء التنظيف الدوري للذاكرة...');
    
    // إزالة العناصر المنتهية الصلاحية
    _removeExpiredItems();
    
    // تنظيف العناصر قليلة الاستخدام
    _cleanupLowUsageItems();
    
    print('✅ تم التنظيف الدوري: ${_memoryCache.length} عنصر متبقي');
  }

  /// إزالة العناصر المنتهية الصلاحية
  void _removeExpiredItems() {
    final expiredKeys = <String>[];
    
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      print('🗑️ تم إزالة ${expiredKeys.length} عنصر منتهي الصلاحية');
    }
  }

  /// تنظيف LRU
  void _performLRUCleanup() {
    final targetSize = (_maxMemoryItems * 0.7).round();
    final itemsToRemove = _memoryCache.length - targetSize;
    
    if (itemsToRemove <= 0) return;
    
    // ترتيب حسب آخر وصول
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) {
        final aAccess = _lastAccess[a.key] ?? DateTime(1970);
        final bAccess = _lastAccess[b.key] ?? DateTime(1970);
        return aAccess.compareTo(bAccess);
      });
    
    // إزالة العناصر الأقل استخداماً
    for (int i = 0; i < itemsToRemove; i++) {
      remove(sortedEntries[i].key);
    }
    
    print('🧹 تم تنظيف LRU: إزالة $itemsToRemove عنصر');
  }

  /// تنظيف العناصر قليلة الاستخدام
  void _cleanupLowUsageItems() {
    final cutoffTime = DateTime.now().subtract(Duration(hours: 6));
    final lowUsageKeys = <String>[];
    
    for (final entry in _memoryCache.entries) {
      final lastAccess = _lastAccess[entry.key];
      final accessCount = _accessCounts[entry.key] ?? 0;
      
      if (lastAccess != null && 
          lastAccess.isBefore(cutoffTime) && 
          accessCount < 3) {
        lowUsageKeys.add(entry.key);
      }
    }
    
    for (final key in lowUsageKeys) {
      remove(key);
    }
    
    if (lowUsageKeys.isNotEmpty) {
      print('🗑️ تم إزالة ${lowUsageKeys.length} عنصر قليل الاستخدام');
    }
  }

  /// تحرير مساحة في الذاكرة
  void _freeMemorySpace(int requiredSize) {
    int freedSize = 0;
    final keysToRemove = <String>[];
    
    // ترتيب حسب الحجم (الأكبر أولاً) وآخر وصول
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) {
        final sizeComparison = b.value.size.compareTo(a.value.size);
        if (sizeComparison != 0) return sizeComparison;
        
        final aAccess = _lastAccess[a.key] ?? DateTime(1970);
        final bAccess = _lastAccess[b.key] ?? DateTime(1970);
        return aAccess.compareTo(bAccess);
      });
    
    for (final entry in sortedEntries) {
      keysToRemove.add(entry.key);
      freedSize += entry.value.size;
      
      if (freedSize >= requiredSize) break;
    }
    
    for (final key in keysToRemove) {
      remove(key);
    }
    
    print('💾 تم تحرير ${_formatSize(freedSize)} من الذاكرة');
  }

  /// ضغط العناصر الكبيرة
  Future<void> _compressLargeItems() async {
    // يمكن تطبيق ضغط للعناصر الكبيرة هنا
    // حالياً نتركها للتطوير المستقبلي
  }

  /// إعادة تنظيم الكاش
  void _reorganizeCache() {
    // ترتيب الكاش حسب الأولوية (الأكثر استخداماً أولاً)
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) {
        final aScore = _calculatePriorityScore(a.key, a.value);
        final bScore = _calculatePriorityScore(b.key, b.value);
        return bScore.compareTo(aScore);
      });
    
    _memoryCache.clear();
    for (final entry in sortedEntries) {
      _memoryCache[entry.key] = entry.value;
    }
  }

  /// حساب نقاط الأولوية
  double _calculatePriorityScore(String key, CacheEntry entry) {
    final accessCount = _accessCounts[key] ?? 0;
    final lastAccess = _lastAccess[key] ?? DateTime(1970);
    final age = DateTime.now().difference(entry.createdAt).inMinutes;
    final recency = DateTime.now().difference(lastAccess).inMinutes;
    
    // نقاط الأولوية بناءً على الاستخدام والحداثة
    double score = accessCount * 10.0; // نقاط الاستخدام
    score += (1440 - recency.clamp(0, 1440)) / 1440 * 50; // نقاط الحداثة
    score -= age / 1440 * 20; // خصم للعمر
    
    return score.clamp(0, 100);
  }

  /// تقدير حجم البيانات
  int _estimateSize(dynamic data) {
    if (data == null) return 0;
    
    if (data is String) {
      return data.length * 2; // UTF-16
    } else if (data is List) {
      return data.length * 8 + 100; // تقدير تقريبي
    } else if (data is Map) {
      return data.length * 16 + 100; // تقدير تقريبي
    } else {
      return 100; // حجم افتراضي
    }
  }

  /// تنسيق حجم البيانات
  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// الحصول على إحصائيات الذاكرة
  MemoryStats getStats() {
    return MemoryStats(
      totalItems: _memoryCache.length,
      totalSize: _currentMemorySize,
      maxItems: _maxMemoryItems,
      maxSize: _maxMemorySize,
      hitRate: _calculateHitRate(),
      averageItemSize: _memoryCache.isNotEmpty ? _currentMemorySize / _memoryCache.length : 0,
    );
  }

  /// حساب معدل النجاح
  double _calculateHitRate() {
    if (_accessCounts.isEmpty) return 0.0;
    
    final totalAccesses = _accessCounts.values.reduce((a, b) => a + b);
    final uniqueItems = _accessCounts.length;
    
    return uniqueItems / totalAccesses;
  }

  void dispose() {
    stopManagement();
    clear();
  }
}

/// عنصر الكاش
class CacheEntry<T> {
  final String key;
  final T data;
  final int size;
  final DateTime createdAt;
  final DateTime expiresAt;
  int accessCount;

  CacheEntry({
    required this.key,
    required this.data,
    required this.size,
    required this.createdAt,
    required this.expiresAt,
    this.accessCount = 0,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Duration get age => DateTime.now().difference(createdAt);
  
  Duration get timeToExpiry => expiresAt.difference(DateTime.now());
}

/// إحصائيات الذاكرة
class MemoryStats {
  final int totalItems;
  final int totalSize;
  final int maxItems;
  final int maxSize;
  final double hitRate;
  final double averageItemSize;

  MemoryStats({
    required this.totalItems,
    required this.totalSize,
    required this.maxItems,
    required this.maxSize,
    required this.hitRate,
    required this.averageItemSize,
  });

  double get utilizationPercent => (totalItems / maxItems) * 100;
  double get sizeUtilizationPercent => (totalSize / maxSize) * 100;
  
  Map<String, dynamic> toMap() {
    return {
      'totalItems': totalItems,
      'totalSize': totalSize,
      'maxItems': maxItems,
      'maxSize': maxSize,
      'hitRate': hitRate,
      'averageItemSize': averageItemSize,
      'utilizationPercent': utilizationPercent,
      'sizeUtilizationPercent': sizeUtilizationPercent,
    };
  }
}
