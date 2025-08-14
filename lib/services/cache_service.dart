import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_model.dart';

class CacheService {
  static const String _lessonsKey = 'cached_lessons';
  static const String _lessonPrefix = 'cached_lesson_';
  static const String _cacheTimeKey = 'cache_timestamp';
  static const String _cacheMetadataKey = 'cache_metadata';
  static const String _cacheAccessKey = 'cache_access_';
  
  // إعدادات الكاش المحسنة
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50 MB
  static const int _maxLessonsInMemory = 20;
  static const int _defaultCacheValidityMinutes = 60;
  static const int _maxCacheValidityMinutes = 24 * 60; // 24 ساعة
  
  // كاش الذاكرة للوصول السريع
  static final Map<String, LessonModel> _memoryCache = {};
  static final Map<String, DateTime> _memoryCacheAccess = {};

  /// حفظ قائمة الدروس في الكاش مع ضغط وتحسين
  static Future<void> cacheLessons(List<LessonModel> lessons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تنظيف الكاش القديم قبل الحفظ
      await _cleanupOldCache();
      
      // تقسيم الدروس حسب الأولوية
      final prioritizedLessons = _prioritizeLessons(lessons);
      
      // حفظ الدروس عالية الأولوية في الذاكرة
      _updateMemoryCache(prioritizedLessons.take(_maxLessonsInMemory).toList());
      
      // ضغط وحفظ جميع الدروس
      final compressedData = await _compressLessons(lessons);
      await prefs.setString(_lessonsKey, compressedData);
      
      // حفظ metadata للكاش
      await _saveCacheMetadata(lessons.length, DateTime.now());
      
      print('✅ تم حفظ ${lessons.length} درس في الكاش (${compressedData.length} بايت)');
    } catch (e) {
      print('❌ خطأ في حفظ الدروس في الكاش: $e');
    }
  }

  /// استرجاع قائمة الدروس من الكاش مع نظام أولويات
  static Future<List<LessonModel>> getCachedLessons({int? unit, bool prioritizeRecent = true}) async {
    try {
      // البحث في كاش الذاكرة أولاً
      final memoryLessons = _getFromMemoryCache(unit: unit);
      if (memoryLessons.isNotEmpty && prioritizeRecent) {
        print('🚀 تم استرجاع ${memoryLessons.length} درس من كاش الذاكرة');
        return memoryLessons;
      }
      
      // البحث في الكاش المحلي
      final prefs = await SharedPreferences.getInstance();
      final compressedData = prefs.getString(_lessonsKey);
      
      if (compressedData == null || compressedData.isEmpty) {
        return memoryLessons; // إرجاع ما في الذاكرة على الأقل
      }
      
      // فحص صحة الكاش
      if (!await _isCacheValid()) {
        print('⚠️ انتهت صلاحية الكاش، سيتم التحديث');
        return memoryLessons;
      }
      
      // إلغاء ضغط واسترجاع الدروس
      final lessons = await _decompressLessons(compressedData);
      
      // تحديث كاش الذاكرة بالدروس المطلوبة
      final filteredLessons = unit != null 
          ? lessons.where((lesson) => lesson.unit == unit).toList()
          : lessons;
      
      _updateMemoryCache(filteredLessons.take(_maxLessonsInMemory).toList());
      
      print('📦 تم استرجاع ${filteredLessons.length} درس من الكاش المحلي');
      return filteredLessons;
    } catch (e) {
      print('❌ خطأ في استرجاع الدروس من الكاش: $e');
      return _getFromMemoryCache(unit: unit);
    }
  }

  /// حفظ درس واحد في الكاش مع تحديث الذاكرة
  static Future<void> cacheLesson(LessonModel lesson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ في الذاكرة
      _memoryCache[lesson.id] = lesson;
      _memoryCacheAccess[lesson.id] = DateTime.now();
      
      // حفظ في التخزين المحلي
      final compressedLesson = await _compressLesson(lesson);
      await prefs.setString('$_lessonPrefix${lesson.id}', compressedLesson);
      
      // تسجيل وقت الوصول
      await _recordAccess(lesson.id);
      
      print('💾 تم حفظ الدرس ${lesson.title} في الكاش');
    } catch (e) {
      print('❌ خطأ في حفظ الدرس في الكاش: $e');
    }
  }

  /// استرجاع درس واحد من الكاش مع أولوية للذاكرة
  static Future<LessonModel?> getCachedLesson(String lessonId) async {
    try {
      // البحث في كاش الذاكرة أولاً
      if (_memoryCache.containsKey(lessonId)) {
        _memoryCacheAccess[lessonId] = DateTime.now();
        print('🚀 تم استرجاع الدرس من كاش الذاكرة: $lessonId');
        return _memoryCache[lessonId];
      }
      
      // البحث في التخزين المحلي
      final prefs = await SharedPreferences.getInstance();
      final compressedLesson = prefs.getString('$_lessonPrefix$lessonId');
      
      if (compressedLesson == null) return null;
      
      // إلغاء ضغط الدرس
      final lesson = await _decompressLesson(compressedLesson);
      
      // إضافة للذاكرة للوصول السريع لاحقاً
      _memoryCache[lessonId] = lesson;
      _memoryCacheAccess[lessonId] = DateTime.now();
      
      // تنظيف كاش الذاكرة إذا امتلأ
      await _cleanupMemoryCache();
      
      // تسجيل وقت الوصول
      await _recordAccess(lessonId);
      
      print('📦 تم استرجاع الدرس من الكاش المحلي: ${lesson.title}');
      return lesson;
    } catch (e) {
      print('❌ خطأ في استرجاع الدرس من الكاش: $e');
      return null;
    }
  }

  /// الحصول على عمر الكاش مع معلومات إضافية
  static Future<CacheInfo?> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimeKey);
      final metadataString = prefs.getString(_cacheMetadataKey);
      
      if (timestamp == null) return null;
      
      final cacheAge = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final ageInMinutes = DateTime.now().difference(cacheAge).inMinutes;
      
      CacheMetadata? metadata;
      if (metadataString != null) {
        final metadataMap = jsonDecode(metadataString);
        metadata = CacheMetadata.fromMap(metadataMap);
      }
      
      return CacheInfo(
        lastUpdate: cacheAge,
        ageInMinutes: ageInMinutes,
        isValid: ageInMinutes < _defaultCacheValidityMinutes,
        metadata: metadata,
        memoryItemsCount: _memoryCache.length,
      );
    } catch (e) {
      return null;
    }
  }

  /// مسح جميع بيانات الكاش مع تنظيف شامل
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // مسح كاش الذاكرة
      _memoryCache.clear();
      _memoryCacheAccess.clear();
      
      // مسح الكاش المحلي
      for (final key in keys) {
        if (key.startsWith(_lessonPrefix) || 
            key == _lessonsKey || 
            key == _cacheTimeKey ||
            key == _cacheMetadataKey ||
            key.startsWith(_cacheAccessKey)) {
          await prefs.remove(key);
        }
      }
      
      print('🧹 تم مسح جميع بيانات الكاش');
    } catch (e) {
      print('❌ خطأ في مسح الكاش: $e');
    }
  }

  /// التحقق من صحة الكاش مع نظام انتهاء صلاحية ذكي
  static Future<bool> isCacheValid({int? customMaxAgeMinutes}) async {
    try {
      final cacheInfo = await getCacheInfo();
      if (cacheInfo == null) return false;
      
      final maxAge = customMaxAgeMinutes ?? _defaultCacheValidityMinutes;
      return cacheInfo.ageInMinutes < maxAge;
    } catch (e) {
      return false;
    }
  }

  /// تحسين الكاش وتنظيف البيانات القديمة
  static Future<void> optimizeCache() async {
    try {
      print('🔧 بدء تحسين الكاش...');
      
      // تنظيف كاش الذاكرة
      await _cleanupMemoryCache();
      
      // تنظيف الكاش القديم
      await _cleanupOldCache();
      
      // ضغط البيانات المتبقية
      await _compactCache();
      
      print('✅ تم تحسين الكاش بنجاح');
    } catch (e) {
      print('❌ خطأ في تحسين الكاش: $e');
    }
  }

  // === الدوال المساعدة الخاصة ===

  /// ترتيب الدروس حسب الأولوية
  static List<LessonModel> _prioritizeLessons(List<LessonModel> lessons) {
    final sortedLessons = List<LessonModel>.from(lessons);
    
    sortedLessons.sort((a, b) {
      // أولوية للوحدة الأولى
      if (a.unit != b.unit) {
        return a.unit.compareTo(b.unit);
      }
      
      // ثم حسب الترتيب
      return a.order.compareTo(b.order);
    });
    
    return sortedLessons;
  }

  /// تحديث كاش الذاكرة
  static void _updateMemoryCache(List<LessonModel> lessons) {
    final now = DateTime.now();
    
    for (final lesson in lessons) {
      _memoryCache[lesson.id] = lesson;
      _memoryCacheAccess[lesson.id] = now;
    }
    
    // تنظيف إذا امتلأ
    if (_memoryCache.length > _maxLessonsInMemory) {
      _cleanupMemoryCache();
    }
  }

  /// الحصول من كاش الذاكرة
  static List<LessonModel> _getFromMemoryCache({int? unit}) {
    final lessons = _memoryCache.values.toList();
    
    if (unit != null) {
      return lessons.where((lesson) => lesson.unit == unit).toList();
    }
    
    return lessons;
  }

  /// تنظيف كاش الذاكرة باستخدام LRU
  static Future<void> _cleanupMemoryCache() async {
    if (_memoryCache.length <= _maxLessonsInMemory) return;
    
    // ترتيب حسب آخر وصول (LRU)
    final sortedEntries = _memoryCacheAccess.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // إزالة النصف الأقل استخداماً
    final toRemove = sortedEntries.take(_memoryCache.length ~/ 2);
    
    for (final entry in toRemove) {
      _memoryCache.remove(entry.key);
      _memoryCacheAccess.remove(entry.key);
    }
    
    print('🧹 تم تنظيف كاش الذاكرة: إزالة ${toRemove.length} عنصر');
  }

  /// تنظيف الكاش القديم
  static Future<void> _cleanupOldCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now();
      
      for (final key in keys) {
        if (key.startsWith(_cacheAccessKey)) {
          final accessTime = prefs.getInt(key);
          if (accessTime != null) {
            final lastAccess = DateTime.fromMillisecondsSinceEpoch(accessTime);
            final ageInHours = now.difference(lastAccess).inHours;
            
            // إزالة البيانات التي لم يتم الوصول إليها لأكثر من 48 ساعة
            if (ageInHours > 48) {
              final lessonId = key.replaceFirst(_cacheAccessKey, '');
              await prefs.remove('$_lessonPrefix$lessonId');
              await prefs.remove(key);
            }
          }
        }
      }
    } catch (e) {
      print('❌ خطأ في تنظيف الكاش القديم: $e');
    }
  }

  /// ضغط قائمة الدروس
  static Future<String> _compressLessons(List<LessonModel> lessons) async {
    try {
      final lessonsJson = lessons.map((lesson) => lesson.toMap()).toList();
      final jsonString = jsonEncode(lessonsJson);
      
      // ضغط البيانات باستخدام gzip
      final bytes = utf8.encode(jsonString);
      final compressed = gzip.encode(bytes);
      
      return base64Encode(compressed);
    } catch (e) {
      // في حالة فشل الضغط، إرجاع البيانات بدون ضغط
      final lessonsJson = lessons.map((lesson) => lesson.toMap()).toList();
      return jsonEncode(lessonsJson);
    }
  }

  /// إلغاء ضغط قائمة الدروس
  static Future<List<LessonModel>> _decompressLessons(String compressedData) async {
    try {
      List<dynamic> lessonsJson;
      
      try {
        // محاولة إلغاء الضغط
        final compressed = base64Decode(compressedData);
        final decompressed = gzip.decode(compressed);
        final jsonString = utf8.decode(decompressed);
        lessonsJson = jsonDecode(jsonString) as List;
      } catch (e) {
        // إذا فشل إلغاء الضغط، افترض أن البيانات غير مضغوطة
        lessonsJson = jsonDecode(compressedData) as List;
      }
      
      return lessonsJson
          .map((json) => LessonModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ خطأ في إلغاء ضغط الدروس: $e');
      return [];
    }
  }

  /// ضغط درس واحد
  static Future<String> _compressLesson(LessonModel lesson) async {
    try {
      final jsonString = jsonEncode(lesson.toMap());
      final bytes = utf8.encode(jsonString);
      final compressed = gzip.encode(bytes);
      return base64Encode(compressed);
    } catch (e) {
      return jsonEncode(lesson.toMap());
    }
  }

  /// إلغاء ضغط درس واحد
  static Future<LessonModel> _decompressLesson(String compressedData) async {
    try {
      Map<String, dynamic> lessonJson;
      
      try {
        final compressed = base64Decode(compressedData);
        final decompressed = gzip.decode(compressed);
        final jsonString = utf8.decode(decompressed);
        lessonJson = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        lessonJson = jsonDecode(compressedData) as Map<String, dynamic>;
      }
      
      return LessonModel.fromMap(lessonJson);
    } catch (e) {
      throw Exception('فشل في إلغاء ضغط الدرس: $e');
    }
  }

  /// حفظ metadata الكاش
  static Future<void> _saveCacheMetadata(int lessonsCount, DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final metadata = CacheMetadata(
        lessonsCount: lessonsCount,
        lastUpdate: timestamp,
        version: '2.0',
      );
      
      await prefs.setString(_cacheMetadataKey, jsonEncode(metadata.toMap()));
      await prefs.setInt(_cacheTimeKey, timestamp.millisecondsSinceEpoch);
    } catch (e) {
      print('❌ خطأ في حفظ metadata الكاش: $e');
    }
  }

  /// تسجيل وقت الوصول
  static Future<void> _recordAccess(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_cacheAccessKey$lessonId', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // تجاهل أخطاء تسجيل الوصول
    }
  }

  /// ضغط الكاش
  static Future<void> _compactCache() async {
    try {
      // إعادة تنظيم البيانات وإزالة التكرار
      final lessons = await getCachedLessons();
      if (lessons.isNotEmpty) {
        await cacheLessons(lessons);
      }
    } catch (e) {
      print('❌ خطأ في ضغط الكاش: $e');
    }
  }

  /// التحقق من صحة الكاش الداخلي
  static Future<bool> _isCacheValid() async {
    return await isCacheValid();
  }
}

/// معلومات الكاش
class CacheInfo {
  final DateTime lastUpdate;
  final int ageInMinutes;
  final bool isValid;
  final CacheMetadata? metadata;
  final int memoryItemsCount;

  CacheInfo({
    required this.lastUpdate,
    required this.ageInMinutes,
    required this.isValid,
    this.metadata,
    required this.memoryItemsCount,
  });
}

/// metadata الكاش
class CacheMetadata {
  final int lessonsCount;
  final DateTime lastUpdate;
  final String version;

  CacheMetadata({
    required this.lessonsCount,
    required this.lastUpdate,
    required this.version,
  });

  Map<String, dynamic> toMap() {
    return {
      'lessonsCount': lessonsCount,
      'lastUpdate': lastUpdate.toIso8601String(),
      'version': version,
    };
  }

  factory CacheMetadata.fromMap(Map<String, dynamic> map) {
    return CacheMetadata(
      lessonsCount: map['lessonsCount'] ?? 0,
      lastUpdate: DateTime.parse(map['lastUpdate'] ?? DateTime.now().toIso8601String()),
      version: map['version'] ?? '1.0',
    );
  }
}
