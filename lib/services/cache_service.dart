import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/lesson_model.dart';

class CacheService {
  static const String _lessonsKey = 'cached_lessons';
  static const String _lessonPrefix = 'cached_lesson_';
  static const String _cacheTimeKey = 'cache_timestamp';
  static const String _cacheVersionKey = 'cache_version';
  static const String _unitCachePrefix = 'cached_unit_';
  static const String _metadataKey = 'cache_metadata';
  
  // إعدادات التخزين المؤقت
  static const int _defaultCacheValidityMinutes = 60; // ساعة واحدة
  static const int _offlineCacheValidityHours = 24; // 24 ساعة في وضع عدم الاتصال
  static const String _currentCacheVersion = '2.0';

  /// حفظ قائمة الدروس في الكاش مع ضغط البيانات
  static Future<void> cacheLessons(List<LessonModel> lessons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final lessonsJson = lessons.map((lesson) => lesson.toMap()).toList();
      final compressedData = _compressData(jsonEncode(lessonsJson));
      
      await prefs.setString(_lessonsKey, compressedData);
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(_cacheVersionKey, _currentCacheVersion);
      
      // حفظ metadata للتحسين
      final metadata = {
        'totalLessons': lessons.length,
        'units': lessons.map((l) => l.unit).toSet().toList(),
        'lastUpdate': DateTime.now().toIso8601String(),
        'dataSize': compressedData.length,
      };
      await prefs.setString(_metadataKey, jsonEncode(metadata));
      
      // حفظ الدروس حسب الوحدة للتحميل التدريجي
      await _cacheLessonsByUnits(lessons);
      
      print('✅ تم حفظ ${lessons.length} درس في الكاش مع ضغط البيانات');
    } catch (e) {
      print('❌ خطأ في حفظ الدروس في الكاش: $e');
    }
  }

  /// حفظ الدروس حسب الوحدات للتحميل التدريجي
  static Future<void> _cacheLessonsByUnits(List<LessonModel> lessons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unitGroups = <int, List<LessonModel>>{};
      
      // تجميع الدروس حسب الوحدة
      for (var lesson in lessons) {
        unitGroups.putIfAbsent(lesson.unit, () => []).add(lesson);
      }
      
      // حفظ كل وحدة منفصلة
      for (var entry in unitGroups.entries) {
        final unitLessons = entry.value.map((l) => l.toMap()).toList();
        final compressedUnitData = _compressData(jsonEncode(unitLessons));
        await prefs.setString('$_unitCachePrefix${entry.key}', compressedUnitData);
      }
    } catch (e) {
      print('❌ خطأ في حفظ الدروس حسب الوحدات: $e');
    }
  }

  /// استرجاع قائمة الدروس من الكاش مع دعم التحميل التدريجي
  static Future<List<LessonModel>> getCachedLessons({int? unit, bool prioritizeUnit = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (unit != null && prioritizeUnit) {
        return await _getCachedLessonsByUnit(unit);
      }
      
      final lessonsString = prefs.getString(_lessonsKey);
      if (lessonsString == null) return [];
      
      // فك ضغط البيانات
      final decompressedData = _decompressData(lessonsString);
      final lessonsJson = jsonDecode(decompressedData) as List;
      
      final lessons = lessonsJson
          .map((json) => LessonModel.fromMap(json as Map<String, dynamic>))
          .toList();
      
      if (unit != null) {
        return lessons.where((lesson) => lesson.unit == unit).toList();
      }
      
      return lessons;
    } catch (e) {
      print('❌ خطأ في استرجاع الدروس من الكاش: $e');
      return [];
    }
  }

  /// استرجاع دروس وحدة معينة من الكاش
  static Future<List<LessonModel>> _getCachedLessonsByUnit(int unit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unitData = prefs.getString('$_unitCachePrefix$unit');
      
      if (unitData == null) return [];
      
      final decompressedData = _decompressData(unitData);
      final lessonsJson = jsonDecode(decompressedData) as List;
      
      return lessonsJson
          .map((json) => LessonModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ خطأ في استرجاع دروس الوحدة $unit: $e');
      return [];
    }
  }

  /// حفظ درس واحد في الكاش مع تحسينات
  static Future<void> cacheLesson(LessonModel lesson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final compressedLesson = _compressData(jsonEncode(lesson.toMap()));
      await prefs.setString('$_lessonPrefix${lesson.id}', compressedLesson);
      
      // تحديث timestamp للدرس
      await prefs.setInt('${_lessonPrefix}${lesson.id}_timestamp', 
          DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('❌ خطأ في حفظ الدرس في الكاش: $e');
    }
  }

  /// استرجاع درس واحد من الكاش
  static Future<LessonModel?> getCachedLesson(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessonString = prefs.getString('$_lessonPrefix$lessonId');
      
      if (lessonString == null) return null;
      
      final decompressedData = _decompressData(lessonString);
      final lessonJson = jsonDecode(decompressedData) as Map<String, dynamic>;
      return LessonModel.fromMap(lessonJson);
    } catch (e) {
      print('❌ خطأ في استرجاع الدرس من الكاش: $e');
      return null;
    }
  }

  /// الحصول على عمر الكاش مع دعم الوضع غير المتصل
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

  /// التحقق من صحة الكاش مع دعم الوضع غير المتصل
  static Future<bool> isCacheValid({int? maxAgeMinutes}) async {
    try {
      final cacheAge = await getCacheAge();
      if (cacheAge == null) return false;
      
      final isOnline = await _checkConnectivity();
      final effectiveMaxAge = maxAgeMinutes ?? 
          (isOnline ? _defaultCacheValidityMinutes : _offlineCacheValidityHours * 60);
      
      final age = DateTime.now().difference(cacheAge).inMinutes;
      final isValid = age < effectiveMaxAge;
      
      // التحقق من إصدار الكاش
      final prefs = await SharedPreferences.getInstance();
      final cacheVersion = prefs.getString(_cacheVersionKey);
      final isVersionValid = cacheVersion == _currentCacheVersion;
      
      return isValid && isVersionValid;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على معلومات الكاش
  static Future<CacheInfo> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataString = prefs.getString(_metadataKey);
      final cacheAge = await getCacheAge();
      final isValid = await isCacheValid();
      
      Map<String, dynamic> metadata = {};
      if (metadataString != null) {
        metadata = jsonDecode(metadataString);
      }
      
      return CacheInfo(
        isValid: isValid,
        cacheAge: cacheAge,
        totalLessons: metadata['totalLessons'] ?? 0,
        availableUnits: List<int>.from(metadata['units'] ?? []),
        dataSize: metadata['dataSize'] ?? 0,
        lastUpdate: metadata['lastUpdate'] != null 
            ? DateTime.parse(metadata['lastUpdate']) 
            : null,
      );
    } catch (e) {
      return CacheInfo.empty();
    }
  }

  /// مسح جميع بيانات الكاش مع تحسينات
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final cacheKeys = keys.where((key) => 
          key.startsWith(_lessonPrefix) || 
          key.startsWith(_unitCachePrefix) ||
          key == _lessonsKey || 
          key == _cacheTimeKey ||
          key == _cacheVersionKey ||
          key == _metadataKey).toList();
      
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
      
      print('✅ تم مسح ${cacheKeys.length} عنصر من الكاش');
    } catch (e) {
      print('❌ خطأ في مسح الكاش: $e');
    }
  }

  /// تحديث الكاش جزئياً
  static Future<void> updateCachePartially(List<LessonModel> newLessons) async {
    try {
      final existingLessons = await getCachedLessons();
      final updatedLessons = <String, LessonModel>{};
      
      // إضافة الدروس الموجودة
      for (var lesson in existingLessons) {
        updatedLessons[lesson.id] = lesson;
      }
      
      // تحديث/إضافة الدروس الجديدة
      for (var lesson in newLessons) {
        updatedLessons[lesson.id] = lesson;
      }
      
      await cacheLessons(updatedLessons.values.toList());
      print('✅ تم تحديث الكاش جزئياً بـ ${newLessons.length} درس');
    } catch (e) {
      print('❌ خطأ في التحديث الجزئي للكاش: $e');
    }
  }

  /// ضغط البيانات لتوفير المساحة
  static String _compressData(String data) {
    try {
      final bytes = utf8.encode(data);
      final compressed = gzip.encode(bytes);
      return base64.encode(compressed);
    } catch (e) {
      // في حالة فشل الضغط، إرجاع البيانات الأصلية
      return data;
    }
  }

  /// فك ضغط البيانات
  static String _decompressData(String compressedData) {
    try {
      final compressed = base64.decode(compressedData);
      final bytes = gzip.decode(compressed);
      return utf8.decode(bytes);
    } catch (e) {
      // في حالة فشل فك الضغط، اعتبار البيانات غير مضغوطة
      return compressedData;
    }
  }

  /// فحص الاتصال بالإنترنت
  static Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// تنظيف الكاش القديم تلقائياً
  static Future<void> cleanupOldCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now();
      
      for (final key in keys) {
        if (key.startsWith(_lessonPrefix) && key.endsWith('_timestamp')) {
          final timestamp = prefs.getInt(key);
          if (timestamp != null) {
            final age = now.difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
            if (age.inDays > 7) { // مسح الكاش الأقدم من أسبوع
              final lessonKey = key.replaceAll('_timestamp', '');
              await prefs.remove(key);
              await prefs.remove(lessonKey);
            }
          }
        }
      }
    } catch (e) {
      print('❌ خطأ في تنظيف الكاش القديم: $e');
    }
  }
}

/// معلومات الكاش
class CacheInfo {
  final bool isValid;
  final DateTime? cacheAge;
  final int totalLessons;
  final List<int> availableUnits;
  final int dataSize;
  final DateTime? lastUpdate;

  CacheInfo({
    required this.isValid,
    this.cacheAge,
    required this.totalLessons,
    required this.availableUnits,
    required this.dataSize,
    this.lastUpdate,
  });

  factory CacheInfo.empty() {
    return CacheInfo(
      isValid: false,
      totalLessons: 0,
      availableUnits: [],
      dataSize: 0,
    );
  }

  String get formattedSize {
    if (dataSize < 1024) return '${dataSize}B';
    if (dataSize < 1024 * 1024) return '${(dataSize / 1024).toStringAsFixed(1)}KB';
    return '${(dataSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String? get ageDescription {
    if (cacheAge == null) return null;
    final age = DateTime.now().difference(cacheAge!);
    if (age.inMinutes < 60) return '${age.inMinutes} دقيقة';
    if (age.inHours < 24) return '${age.inHours} ساعة';
    return '${age.inDays} يوم';
  }
}
