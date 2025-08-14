import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/lesson_model.dart';
import '../services/local_service.dart';
import '../services/firebase_service.dart';

class LessonProvider with ChangeNotifier {
  List<LessonModel> _lessons = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, bool> _completedLessons = {};

  List<LessonModel> get lessons => _lessons;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, bool> get completedLessons => _completedLessons;

  LessonProvider() {
    _loadCompletedLessons();
  }

  // Load lessons from local JSON files first, then try Firebase
  Future<void> loadLessons() async {
    try {
      _setLoading(true);
      _clearError();

      print('🔄 تحميل الدروس...');

      // Try to load from local JSON files first
      try {
        _lessons = await LocalService.loadLessonsFromAssets();
        print('✅ تم تحميل ${_lessons.length} درس من الملفات المحلية');
        
        if (_lessons.isNotEmpty) {
          notifyListeners();
        }
      } catch (e) {
        print('⚠️ فشل في تحميل الدروس المحلية: $e');
      }

      // Try to load from Firebase as backup/update
      try {
        final firebaseLessons = await FirebaseService.getLessons()
            .timeout(const Duration(seconds: 10));
        
        if (firebaseLessons.isNotEmpty) {
          print('✅ تم تحميل ${firebaseLessons.length} درس من Firebase');
          _lessons = firebaseLessons;
        }
      } catch (e) {
        print('⚠️ فشل في تحميل الدروس من Firebase: $e');
        if (_lessons.isEmpty) {
          throw Exception('فشل في تحميل الدروس من جميع المصادر');
        }
      }

      // Load completed lessons status
      await _loadCompletedLessons();
      
      print('📚 إجمالي الدروس المحملة: ${_lessons.length}');
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في تحميل الدروس: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get lessons by unit
  List<LessonModel> getLessonsByUnit(int unit) {
    return _lessons.where((lesson) => lesson.unit == unit).toList();
  }

  // Get lesson by ID
  LessonModel? getLessonById(String id) {
    try {
      return _lessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if lesson is completed
  bool isLessonCompleted(String lessonId) {
    return _completedLessons[lessonId] ?? false;
  }

  // Mark lesson as completed
  Future<void> markLessonCompleted(String lessonId) async {
    _completedLessons[lessonId] = true;
    await _saveCompletedLessons();
    notifyListeners();
  }

  // Get available lessons (unlocked lessons)
  Future<List<LessonModel>> getAvailableLessons() async {
    // For now, return all lessons. Later we can implement unlocking logic
    return _lessons;
  }

  // Get units info with lesson counts and completion status
  Map<int, Map<String, dynamic>> getUnitsInfo() {
    final unitsInfo = <int, Map<String, dynamic>>{};
    
    for (var lesson in _lessons) {
      if (!unitsInfo.containsKey(lesson.unit)) {
        unitsInfo[lesson.unit] = {
          'totalLessons': 0,
          'completedLessons': 0,
          'isUnlocked': true, // For now, all units are unlocked
        };
      }
      
      unitsInfo[lesson.unit]!['totalLessons']++;
      if (isLessonCompleted(lesson.id)) {
        unitsInfo[lesson.unit]!['completedLessons']++;
      }
    }
    
    return unitsInfo;
  }

  // Reset local progress - إضافة جديدة لحل مشكلة إعادة التعيين
  Future<void> resetLocalProgress() async {
    try {
      _completedLessons.clear();
      await _saveCompletedLessons();
      
      // مسح جميع البيانات المحلية المتعلقة بالدروس
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (String key in keys) {
        if (key.startsWith('lesson_') || 
            key.startsWith('quiz_') ||
            key.contains('completed_lessons') ||
            key.contains('lesson_progress')) {
          await prefs.remove(key);
        }
      }
      
      print('🔄 تم إعادة تعيين تقدم الدروس المحلي');
      notifyListeners();
    } catch (e) {
      print('خطأ في إعادة تعيين تقدم الدروس: $e');
    }
  }

  // Load completed lessons from local storage
  Future<void> _loadCompletedLessons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedJson = prefs.getString('completed_lessons') ?? '{}';
      final Map<String, dynamic> completedMap = json.decode(completedJson);
      
      _completedLessons = completedMap.map((key, value) => MapEntry(key, value as bool));
      
      print('📖 تم تحميل ${_completedLessons.length} درس مكتمل');
    } catch (e) {
      print('خطأ في تحميل الدروس المكتملة: $e');
      _completedLessons = {};
    }
  }

  // Save completed lessons to local storage
  Future<void> _saveCompletedLessons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('completed_lessons', json.encode(_completedLessons));
    } catch (e) {
      print('خطأ في حفظ الدروس المكتملة: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
