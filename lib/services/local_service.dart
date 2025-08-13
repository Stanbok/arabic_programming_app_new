import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/lesson_model.dart';

class LocalService {
  static const String _lessonsPath = 'assets/data/python/lessons';
  
  // قائمة ملفات الدروس المحلية
  static const List<String> _localLessonFiles = [
    'lesson_001.json',
    'lesson_002.json',
    'lesson_003.json',
    'lesson_004.json',
  ];

  /// تحميل جميع الدروس المحلية
  static Future<List<LessonModel>> getLocalLessons({int? unit}) async {
    try {
      List<LessonModel> lessons = [];
      
      for (String fileName in _localLessonFiles) {
        try {
          final lessonData = await _loadLessonFromAssets(fileName);
          if (lessonData != null) {
            if (unit == null || lessonData.unit == unit) {
              lessons.add(lessonData);
            }
          }
        } catch (e) {
          print('⚠️ خطأ في تحميل الدرس $fileName: $e');
        }
      }
      
      lessons.sort((a, b) {
        if (a.unit != b.unit) {
          return a.unit.compareTo(b.unit);
        }
        return a.order.compareTo(b.order);
      });
      
      return lessons;
    } catch (e) {
      print('❌ خطأ في تحميل الدروس المحلية: $e');
      return [];
    }
  }

  /// تحميل درس محدد بالمعرف
  static Future<LessonModel?> getLocalLesson(String lessonId) async {
    try {
      for (String fileName in _localLessonFiles) {
        try {
          final lessonData = await _loadLessonFromAssets(fileName);
          if (lessonData != null && lessonData.id == lessonId) {
            return lessonData;
          }
        } catch (e) {
          print('⚠️ خطأ في فحص الملف $fileName: $e');
        }
      }
      
      return null;
    } catch (e) {
      print('❌ خطأ في البحث عن الدرس المحلي: $e');
      return null;
    }
  }

  /// تحميل درس من ملف assets
  static Future<LessonModel?> _loadLessonFromAssets(String fileName) async {
    try {
      final String jsonString = await rootBundle.loadString('$_lessonsPath/$fileName');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // تحويل التواريخ من String إلى DateTime
      if (jsonData['createdAt'] is String) {
        jsonData['createdAt'] = DateTime.parse(jsonData['createdAt']);
      }
      if (jsonData['updatedAt'] is String) {
        jsonData['updatedAt'] = DateTime.parse(jsonData['updatedAt']);
      }
      
      return LessonModel.fromMap(jsonData);
    } catch (e) {
      print('❌ خطأ في تحميل الملف $fileName: $e');
      return null;
    }
  }

  /// التحقق من توفر الدروس المحلية
  static Future<bool> hasLocalLessons() async {
    try {
      final lessons = await getLocalLessons();
      return lessons.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على عدد الدروس المحلية
  static Future<int> getLocalLessonsCount() async {
    try {
      final lessons = await getLocalLessons();
      return lessons.length;
    } catch (e) {
      return 0;
    }
  }

  /// الحصول على الدروس المحلية حسب الوحدة
  static Future<List<LessonModel>> getLocalLessonsByUnit(int unit) async {
    return await getLocalLessons(unit: unit);
  }
}
