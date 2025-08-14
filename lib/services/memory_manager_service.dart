import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/lesson_model.dart';

/// خدمة إدارة الذاكرة المتقدمة
class MemoryManagerService {
  static final MemoryManagerService _instance = MemoryManagerService._internal();
  factory MemoryManagerService() => _instance;
  MemoryManagerService._internal();

  // كاش ذكي مع LRU (Least Recently Used)
  final LRUCache<String, LessonModel> _lessonCache = LRUCache<String, LessonModel>(50);
  final LRUCache<String, List<LessonModel>> _unitCache = LRUCache<String, List<LessonModel>>(10);
  final LRUCache<String, dynamic> _generalCache = LRUCache<String, dynamic>(100);
  
  // مراقبة استخدام الذاكرة
  final Map<String, CacheEntry> _cacheMetrics = {};
  Timer? _cleanupTimer;
  
  // إعدادات إدارة الذاكرة
  static const Duration _cleanupInterval = Duration(minutes: 5);
  static const Duration _entryMaxAge = Duration(minutes: 30);
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB

  /// تهيئة مدير الذاكرة
  Future<void> initialize() async {
    _startPeriodicCleanup();
    print('🧠 تم تهيئة مدير الذاكرة');
  }

  /// بدء التنظيف الدوري
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      _performCleanup();
    });
  }

  /// حفظ درس في الكاش الذكي
  void cacheLessonSmart(LessonModel lesson) {
    final key = lesson.id;
    _lessonCache.put(key, lesson);
    
    _cacheMetrics[key] = CacheEntry(
      key: key,
      size: _estimateLessonSize(lesson),
      accessCount: 1,
      lastAccessed: DateTime.now(),
      created: DateTime.now(),
    );
    
    _checkMemoryLimits();
  }

  /// استرجاع درس من الكاش الذكي
  LessonModel? getCachedLessonSmart(String lessonId) {
    final lesson = _lessonCache.get(lessonId);
    
    if (lesson != null) {
      // تحديث إحصائيات الوصول
      final entry = _cacheMetrics[lessonId];
      if (entry != null) {
        entry.accessCount++;
        entry.lastAccessed = DateTime.now();
      }
    }
    
    return lesson;
  }

  /// حفظ دروس الوحدة في الكاش
  void cacheUnitLessons(int unit, List<LessonModel> lessons) {
    final key = 'unit_$unit';
    _unitCache.put(key, lessons);
    
    final totalSize = lessons.fold<int>(0, (sum, lesson) => sum + _estimateLessonSize(lesson));
    
    _cacheMetrics[key] = CacheEntry(
      key: key,
      size: totalSize,
      accessCount: 1,
      lastAccessed: DateTime.now(),
      created: DateTime.now(),
    );
    
    _checkMemoryLimits();
  }

  /// استرجاع دروس الوحدة من الكاش
  List<LessonModel>? getCachedUnitLessons(int unit) {
    final key = 'unit_$unit';
    final lessons = _unitCache.get(key);
    
    if (lessons != null) {
      final entry = _cacheMetrics[key];
      if (entry != null) {
        entry.accessCount++;
        entry.lastAccessed = DateTime.now();
      }
    }
    
    return lessons;
  }

  /// حفظ بيانات عامة في الكاش
  void cacheData<T>(String key, T data) {
    _generalCache.put(key, data);
    
    _cacheMetrics[key] = CacheEntry(
      key: key,
      size: _estimateDataSize(data),
      accessCount: 1,
      lastAccessed: DateTime.now(),
      created: DateTime.now(),
    );
    
    _checkMemoryLimits();
  }

  /// استرجاع بيانات عامة من الكاش
  T? getCachedData<T>(String key) {
    final data = _generalCache.get(key) as T?;
    
    if (data != null) {
      final entry = _cacheMetrics[key];
      if (entry != null) {
        entry.accessCount++;
        entry.lastAccessed = DateTime.now();
      }
    }
    
    return data;
  }

  /// فحص حدود الذاكرة
  void _checkMemoryLimits() {
    final totalSize = _getTotalCacheSize();
    
    if (totalSize > _maxCacheSize) {
      print('⚠️ تجاوز حد الذاكرة: ${_formatBytes(totalSize)} / ${_formatBytes(_maxCacheSize)}');
      _performAggressiveCleanup();
    }
  }

  /// الحصول على الحجم الكلي للكاش
  int _getTotalCacheSize() {
    return _cacheMetrics.values.fold<int>(0, (sum, entry) => sum + entry.size);
  }

  /// تقدير حجم الدرس
  int _estimateLessonSize(LessonModel lesson) {
    int size = 0;
    
    // حجم النصوص
    size += lesson.title.length * 2; // UTF-16
    size += lesson.description.length * 2;
    
    // حجم الشرائح
    for (final slide in lesson.slides) {
      size += slide.title.length * 2;
      size += slide.content.length * 2;
      size += (slide.codeExample?.length ?? 0) * 2;
    }
    
    // حجم الاختبارات
    for (final question in lesson.quiz) {
      size += question.question.length * 2;
      size += question.options.fold<int>(0, (sum, option) => sum + option.length * 2);
      size += (question.explanation?.length ?? 0) * 2;
    }
    
    // إضافة overhead للكائن
    size += 1024; // تقدير تقريبي
    
    return size;
  }

  /// تقدير حجم البيانات العامة
  int _estimateDataSize(dynamic data) {
    if (data is String) {
      return data.length * 2;
    } else if (data is List) {
      return data.length * 100; // تقدير تقريبي
    } else if (data is Map) {
      return data.length * 200; // تقدير تقريبي
    } else {
      return 1024; // تقدير افتراضي
    }
  }

  /// تنظيف دوري
  void _performCleanup() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    // البحث عن العناصر المنتهية الصلاحية
    for (final entry in _cacheMetrics.entries) {
      if (now.difference(entry.value.lastAccessed) > _entryMaxAge) {
        expiredKeys.add(entry.key);
      }
    }
    
    // إزالة العناصر المنتهية الصلاحية
    for (final key in expiredKeys) {
      _removeFromAllCaches(key);
      _cacheMetrics.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      print('🧹 تم تنظيف ${expiredKeys.length} عنصر منتهي الصلاحية');
    }
  }

  /// تنظيف قوي عند تجاوز حدود الذاكرة
  void _performAggressiveCleanup() {
    // ترتيب العناصر حسب الأولوية (الأقل استخداماً أولاً)
    final sortedEntries = _cacheMetrics.entries.toList()
      ..sort((a, b) {
        // الأولوية للعناصر الأقل استخداماً والأقدم
        final scoreA = a.value.accessCount / DateTime.now().difference(a.value.lastAccessed).inMinutes.clamp(1, 1000);
        final scoreB = b.value.accessCount / DateTime.now().difference(b.value.lastAccessed).inMinutes.clamp(1, 1000);
        return scoreA.compareTo(scoreB);
      });
    
    // إزالة 30% من العناصر الأقل أهمية
    final itemsToRemove = (sortedEntries.length * 0.3).ceil();
    
    for (int i = 0; i < itemsToRemove && i < sortedEntries.length; i++) {
      final key = sortedEntries[i].key;
      _removeFromAllCaches(key);
      _cacheMetrics.remove(key);
    }
    
    print('🗑️ تم إزالة $itemsToRemove عنصر في التنظيف القوي');
  }

  /// إزالة مفتاح من جميع الكاشات
  void _removeFromAllCaches(String key) {
    _lessonCache.remove(key);
    _unitCache.remove(key);
    _generalCache.remove(key);
  }

  /// مسح كاش معين
  void clearCache(CacheType type) {
    switch (type) {
      case CacheType.lessons:
        _lessonCache.clear();
        break;
      case CacheType.units:
        _unitCache.clear();
        break;
      case CacheType.general:
        _generalCache.clear();
        break;
      case CacheType.all:
        _lessonCache.clear();
        _unitCache.clear();
        _generalCache.clear();
        _cacheMetrics.clear();
        break;
    }
  }

  /// الحصول على إحصائيات الذاكرة
  MemoryStats getMemoryStats() {
    final totalSize = _getTotalCacheSize();
    final totalEntries = _cacheMetrics.length;
    
    final accessCounts = _cacheMetrics.values.map((e) => e.accessCount).toList();
    final avgAccessCount = accessCounts.isNotEmpty 
        ? accessCounts.reduce((a, b) => a + b) / accessCounts.length 
        : 0.0;
    
    return MemoryStats(
      totalSize: totalSize,
      totalEntries: totalEntries,
      lessonCacheSize: _lessonCache.length,
      unitCacheSize: _unitCache.length,
      generalCacheSize: _generalCache.length,
      averageAccessCount: avgAccessCount,
      memoryUsagePercentage: (totalSize / _maxCacheSize) * 100,
      oldestEntryAge: _getOldestEntryAge(),
    );
  }

  /// الحصول على عمر أقدم عنصر
  Duration? _getOldestEntryAge() {
    if (_cacheMetrics.isEmpty) return null;
    
    final oldestEntry = _cacheMetrics.values
        .reduce((a, b) => a.created.isBefore(b.created) ? a : b);
    
    return DateTime.now().difference(oldestEntry.created);
  }

  /// تنسيق البايتات
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// تنظيف الموارد
  void dispose() {
    _cleanupTimer?.cancel();
    clearCache(CacheType.all);
  }
}

/// كاش LRU (Least Recently Used)
class LRUCache<K, V> {
  final int _maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  LRUCache(this._maxSize);

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value; // نقل إلى النهاية
    }
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= _maxSize) {
      _cache.remove(_cache.keys.first); // إزالة الأقدم
    }
    _cache[key] = value;
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  int get length => _cache.length;
  bool get isEmpty => _cache.isEmpty;
  bool get isNotEmpty => _cache.isNotEmpty;
}

/// إدخال الكاش
class CacheEntry {
  final String key;
  final int size;
  int accessCount;
  DateTime lastAccessed;
  final DateTime created;

  CacheEntry({
    required this.key,
    required this.size,
    required this.accessCount,
    required this.lastAccessed,
    required this.created,
  });
}

/// نوع الكاش
enum CacheType {
  lessons,
  units,
  general,
  all,
}

/// إحصائيات الذاكرة
class MemoryStats {
  final int totalSize;
  final int totalEntries;
  final int lessonCacheSize;
  final int unitCacheSize;
  final int generalCacheSize;
  final double averageAccessCount;
  final double memoryUsagePercentage;
  final Duration? oldestEntryAge;

  MemoryStats({
    required this.totalSize,
    required this.totalEntries,
    required this.lessonCacheSize,
    required this.unitCacheSize,
    required this.generalCacheSize,
    required this.averageAccessCount,
    required this.memoryUsagePercentage,
    this.oldestEntryAge,
  });

  String get formattedTotalSize {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  bool get isMemoryHigh => memoryUsagePercentage > 80;
  bool get isMemoryFull => memoryUsagePercentage > 95;
}
