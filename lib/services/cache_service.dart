import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_model.dart';

class CacheService {
  static const String _lessonsKey = 'cached_lessons';
  static const String _lessonPrefix = 'cached_lesson_';
  static const String _cacheTimeKey = 'cache_timestamp';

  /// حفظ قائمة الدروس في الكاش
  static Future<void> cacheLessons(List<LessonModel> lessons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessonsJson = lessons.map((lesson) => lesson.toMap()).toList();
      await prefs.setString(_lessonsKey, jsonEncode(lessonsJson));
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      print('💾 تم حفظ ${lessons.length} درس في الكاش');
    } catch (e) {
      print('❌ خطأ في حفظ الدروس في الكاش: $e');
    }
  }

  /// استرجاع قائمة الدروس من الكاش
  static Future<List<LessonModel>> getCachedLessons({int? level}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessonsString = prefs.getString(_lessonsKey);
      
      if (lessonsString == null) return [];
      
      final lessonsJson = jsonDecode(lessonsString) as List;
      final lessons = lessonsJson
          .map((json) => LessonModel.fromMap(json as Map<String, dynamic>))
          .toList();
      
      if (level != null) {
        return lessons.where((lesson) => lesson.level == level).toList();
      }
      
      return lessons;
    } catch (e) {
      print('❌ خطأ في استرجاع الدروس من الكاش: $e');
      return [];
    }
  }

  /// حفظ درس واحد في الكاش
  static Future<void> cacheLesson(LessonModel lesson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_lessonPrefix${lesson.id}', jsonEncode(lesson.toMap()));
      print('💾 تم حفظ الدرس ${lesson.title} في الكاش');
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
      
      final lessonJson = jsonDecode(lessonString) as Map<String, dynamic>;
      return LessonModel.fromMap(lessonJson);
    } catch (e) {
      print('❌ خطأ في استرجاع الدرس من الكاش: $e');
      return null;
    }
  }

  /// الحصول على عمر الكاش
  static Future<DateTime?> getCacheAge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimeKey);
      
      if (timestamp == null) return null;
      
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('❌ خطأ في الحصول على عمر الكاش: $e');
      return null;
    }
  }

  /// مسح جميع بيانات الكاش
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_lessonPrefix) || 
            key == _lessonsKey || 
            key == _cacheTimeKey) {
          await prefs.remove(key);
        }
      }
      
      print('🗑️ تم مسح جميع بيانات الكاش');
    } catch (e) {
      print('❌ خطأ في مسح الكاش: $e');
    }
  }

  /// التحقق من صحة الكاش
  static Future<bool> isCacheValid({int maxAgeMinutes = 30}) async {
    try {
      final cacheAge = await getCacheAge();
      if (cacheAge == null) return false;
      
      final age = DateTime.now().difference(cacheAge).inMinutes;
      return age < maxAgeMinutes;
    } catch (e) {
      print('❌ خطأ في التحقق من صحة الكاش: $e');
      return false;
    }
  }
}
