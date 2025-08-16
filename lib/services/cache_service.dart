import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/lesson_model.dart';

class CacheService {
  static const String _lessonsKey = 'cached_lessons';
  static const String _lessonPrefix = 'cached_lesson_';
  static const String _cacheTimeKey = 'cache_timestamp';
  static const String _unitPrefix = 'cached_unit_';
  static const String _cacheVersionKey = 'cache_version';
  static const int _currentCacheVersion = 2;
  
  static final Map<String, LessonModel> _memoryCache = {};
  static final Map<int, List<LessonModel>> _unitCache = {};
  static DateTime? _memoryCacheTimestamp;
  static const Duration _memoryCacheValidDuration = Duration(minutes: 10);
  
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxLessonsInMemory = 100;

  static Future<void> _initializeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_cacheVersionKey) ?? 1;
      
      if (currentVersion < _currentCacheVersion) {
        await clearCache();
        await prefs.setInt(_cacheVersionKey, _currentCacheVersion);
      }
    } catch (e) {
      print('❌ خطأ في تهيئة الكاش: $e');
    }
  }

  static Future<void> cacheLessons(List<LessonModel> lessons) async {
    try {
      await _initializeCache();
      
      final prefs = await SharedPreferences.getInstance();
      
      final unitGroups = <int, List<LessonModel>>{};
      for (final lesson in lessons) {
        unitGroups.putIfAbsent(lesson.unit, () => []).add(lesson);
      }
      
      // حفظ كل وحدة منفصلة
      final futures = <Future>[];
      for (final entry in unitGroups.entries) {
        final unitKey = '$_unitPrefix${entry.key}';
        final unitLessons = entry.value.map((lesson) => lesson.toMap()).toList();
        futures.add(prefs.setString(unitKey, jsonEncode(unitLessons)));
        
        // تحديث كاش الذاكرة
        _unitCache[entry.key] = List.from(entry.value);
      }
      
      // حفظ جميع الدروس (للتوافق مع النسخة القديمة)
      final lessonsJson = lessons.map((lesson) => lesson.toMap()).toList();
      futures.add(prefs.setString(_lessonsKey, jsonEncode(lessonsJson)));
      futures.add(prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch));
      
      await Future.wait(futures);
      
      // تحديث كاش الذاكرة
      _updateMemoryCache(lessons);
      
      // تنظيف الكاش إذا تجاوز الحد المسموح
      await _cleanupCacheIfNeeded();
      
    } catch (e) {
      print('❌ خطأ في حفظ الدروس في الكاش: $e');
    }
  }

  static Future<List<LessonModel>> getCachedLessons({int? unit}) async {
    try {
      // فحص كاش الذاكرة أولاً
      if (_isMemoryCacheValid()) {
        if (unit != null && _unitCache.containsKey(unit)) {
          return List.from(_unitCache[unit]!);
        } else if (unit == null && _memoryCache.isNotEmpty) {
          return _memoryCache.values.toList();
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // محاولة جلب وحدة محددة أولاً
      if (unit != null) {
        final unitKey = '$_unitPrefix$unit';
        final unitString = prefs.getString(unitKey);
        
        if (unitString != null) {
          final unitJson = jsonDecode(unitString) as List;
          final lessons = unitJson
              .map((json) => LessonModel.fromMap(json as Map<String, dynamic>))
              .toList();
          
          // تحديث كاش الذاكرة
          _unitCache[unit] = List.from(lessons);
          for (final lesson in lessons) {
            _memoryCache[lesson.id] = lesson;
          }
          _memoryCacheTimestamp = DateTime.now();
          
          return lessons;
        }
      }
      
      // الرجوع للكاش العام
      final lessonsString = prefs.getString(_lessonsKey);
      if (lessonsString == null) return [];
      
      final lessonsJson = jsonDecode(lessonsString) as List;
      final lessons = lessonsJson
          .map((json) => LessonModel.fromMap(json as Map<String, dynamic>))
          .toList();
      
      // تحديث كاش الذاكرة
      _updateMemoryCache(lessons);
      
      if (unit != null) {
        return lessons.where((lesson) => lesson.unit == unit).toList();
      }
      
      return lessons;
    } catch (e) {
      print('❌ خطأ في استرجاع الدروس من الكاش: $e');
      return [];
    }
  }

  static Future<void> cacheLesson(LessonModel lesson) async {
    try {
      // تحديث كاش الذاكرة فوراً
      _memoryCache[lesson.id] = lesson;
      
      // تحديث كاش الوحدة في الذاكرة
      if (_unitCache.containsKey(lesson.unit)) {
        final unitLessons = _unitCache[lesson.unit]!;
        final existingIndex = unitLessons.indexWhere((l) => l.id == lesson.id);
        if (existingIndex >= 0) {
          unitLessons[existingIndex] = lesson;
        } else {
          unitLessons.add(lesson);
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_lessonPrefix${lesson.id}', jsonEncode(lesson.toMap()));
      
      // تنظيف كاش الذاكرة إذا تجاوز الحد
      if (_memoryCache.length > _maxLessonsInMemory) {
        _cleanupMemoryCache();
      }
    } catch (e) {
      print('❌ خطأ في حفظ الدرس في الكاش: $e');
    }
  }

  static Future<LessonModel?> getCachedLesson(String lessonId) async {
    try {
      // فحص كاش الذاكرة أولاً
      if (_isMemoryCacheValid() && _memoryCache.containsKey(lessonId)) {
        return _memoryCache[lessonId];
      }
      
      final prefs = await SharedPreferences.getInstance();
      final lessonString = prefs.getString('$_lessonPrefix$lessonId');
      
      if (lessonString == null) return null;
      
      final lessonJson = jsonDecode(lessonString) as Map<String, dynamic>;
      final lesson = LessonModel.fromMap(lessonJson);
      
      // إضافة للكاش في الذاكرة
      _memoryCache[lessonId] = lesson;
      _memoryCacheTimestamp ??= DateTime.now();
      
      return lesson;
    } catch (e) {
      print('❌ خطأ في استرجاع الدرس من الكاش: $e');
      return null;
    }
  }

  static Future<DateTime?> getCacheAge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimeKey);
      
      if (timestamp == null) return null;
      
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final keysToRemove = keys.where((key) => 
        key.startsWith(_lessonPrefix) || 
        key.startsWith(_unitPrefix) ||
        key == _lessonsKey || 
        key == _cacheTimeKey
      ).toList();
      
      // حذف متوازي للمفاتيح
      final futures = keysToRemove.map((key) => prefs.remove(key));
      await Future.wait(futures);
      
      // مسح كاش الذاكرة
      _memoryCache.clear();
      _unitCache.clear();
      _memoryCacheTimestamp = null;
      
    } catch (e) {
      print('❌ خطأ في مسح الكاش: $e');
    }
  }

  static Future<bool> isCacheValid({int maxAgeMinutes = 20}) async {
    try {
      final cacheAge = await getCacheAge();
      if (cacheAge == null) return false;
      
      final age = DateTime.now().difference(cacheAge).inMinutes;
      return age < maxAgeMinutes;
    } catch (e) {
      return false;
    }
  }

  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int totalSize = 0;
      
      for (final key in keys) {
        if (key.startsWith(_lessonPrefix) || 
            key.startsWith(_unitPrefix) ||
            key == _lessonsKey) {
          final value = prefs.getString(key);
          if (value != null) {
            totalSize += value.length * 2; // تقدير تقريبي للحجم
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> _cleanupCacheIfNeeded() async {
    try {
      final cacheSize = await getCacheSize();
      
      if (cacheSize > _maxCacheSize) {
        // حذف الدروس الفردية القديمة أولاً
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys()
            .where((key) => key.startsWith(_lessonPrefix))
            .toList();
        
        // حذف نصف الدروس الفردية
        final keysToRemove = keys.take(keys.length ~/ 2);
        final futures = keysToRemove.map((key) => prefs.remove(key));
        await Future.wait(futures);
      }
    } catch (e) {
      print('❌ خطأ في تنظيف الكاش: $e');
    }
  }

  static void _updateMemoryCache(List<LessonModel> lessons) {
    // تنظيف الكاش إذا كان كبيراً
    if (_memoryCache.length > _maxLessonsInMemory) {
      _cleanupMemoryCache();
    }
    
    // إضافة الدروس الجديدة
    for (final lesson in lessons) {
      _memoryCache[lesson.id] = lesson;
    }
    
    // تحديث كاش الوحدات
    final unitGroups = <int, List<LessonModel>>{};
    for (final lesson in lessons) {
      unitGroups.putIfAbsent(lesson.unit, () => []).add(lesson);
    }
    
    _unitCache.addAll(unitGroups);
    _memoryCacheTimestamp = DateTime.now();
  }

  static void _cleanupMemoryCache() {
    if (_memoryCache.length <= _maxLessonsInMemory) return;
    
    // الاحتفاظ بنصف الدروس فقط
    final entries = _memoryCache.entries.toList();
    _memoryCache.clear();
    
    final keepCount = _maxLessonsInMemory ~/ 2;
    for (int i = entries.length - keepCount; i < entries.length; i++) {
      _memoryCache[entries[i].key] = entries[i].value;
    }
    
    // تنظيف كاش الوحدات أيضاً
    _unitCache.clear();
  }

  static bool _isMemoryCacheValid() {
    if (_memoryCacheTimestamp == null) return false;
    
    final age = DateTime.now().difference(_memoryCacheTimestamp!);
    return age < _memoryCacheValidDuration;
  }

  static void clearMemoryCache() {
    _memoryCache.clear();
    _unitCache.clear();
    _memoryCacheTimestamp = null;
  }

  static Map<String, dynamic> getCacheStats() {
    return {
      'memoryLessons': _memoryCache.length,
      'memoryCacheValid': _isMemoryCacheValid(),
      'unitsCached': _unitCache.length,
      'lastUpdate': _memoryCacheTimestamp?.toIso8601String(),
    };
  }
}
