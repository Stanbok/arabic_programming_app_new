import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/lesson_model.dart';
import '../models/progress_model.dart';
import '../models/quiz_result_model.dart';

class LessonProvider with ChangeNotifier {
  List<LessonModel> _lessons = [];
  LessonModel? _currentLesson;
  ProgressModel? _currentProgress;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasNetworkConnection = true;

  List<LessonModel> get lessons => _lessons;
  LessonModel? get currentLesson => _currentLesson;
  ProgressModel? get currentProgress => _currentProgress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNetworkConnection => _hasNetworkConnection;

  Future<void> loadLessons({int? level}) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🔄 بدء تحميل الدروس...');
      print('📊 المستوى المطلوب: ${level ?? "جميع المستويات"}');
      
      // التحقق من الاتصال أولاً
      _hasNetworkConnection = await FirebaseService.checkConnection()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      
      if (!_hasNetworkConnection) {
        print('❌ لا يوجد اتصال بالإنترنت');
        _setError('لا يوجد اتصال بالإنترنت - تحقق من اتصالك وحاول مرة أخرى');
        return;
      }
      
      // تحميل الدروس مع timeout
      _lessons = await FirebaseService.getLessons(level: level)
          .timeout(const Duration(seconds: 20), onTimeout: () {
        throw Exception('انتهت مهلة تحميل الدروس - تحقق من اتصال الإنترنت');
      });
      
      print('✅ تم تحميل ${_lessons.length} درس');
      
      if (_lessons.isEmpty) {
        print('⚠️ لا توجد دروس متاحة');
        print('💡 تحقق من:');
        print('  - وجود مجموعة "lessons" في Firestore');
        print('  - وجود دروس مع isPublished = true');
        print('  - صحة قواعد الأمان في Firestore');
        _setError('لا توجد دروس متاحة حالياً. تأكد من رفع الدروس في لوحة التحكم.');
      } else {
        print('📋 الدروس المحملة:');
        for (var lesson in _lessons) {
          print('  - ${lesson.title} (المستوى: ${lesson.level}, منشور: ${lesson.isPublished})');
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في تحميل الدروس: $e');
      
      String errorMessage;
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'خطأ في الصلاحيات - تحقق من إعدادات قاعدة البيانات';
      } else if (e.toString().contains('unavailable') || e.toString().contains('انتهت مهلة')) {
        errorMessage = 'خطأ في الاتصال - تحقق من اتصال الإنترنت وحاول مرة أخرى';
        _hasNetworkConnection = false;
      } else if (e.toString().contains('not-found')) {
        errorMessage = 'لم يتم العثور على الدروس - تأكد من رفع الدروس في لوحة التحكم';
      } else {
        errorMessage = 'فشل في تحميل الدروس - حاول مرة أخرى لاحقاً';
      }
      
      _setError(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadLesson(String lessonId, String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('📖 تحميل الدرس: $lessonId');
      
      // تحميل الدرس والتقدم مع timeout
      final lessonFuture = FirebaseService.getLesson(lessonId)
          .timeout(const Duration(seconds: 10));
      final progressFuture = FirebaseService.getLessonProgress(userId, lessonId)
          .timeout(const Duration(seconds: 10));
      
      final results = await Future.wait([lessonFuture, progressFuture]);
      
      _currentLesson = results[0] as LessonModel?;
      _currentProgress = results[1] as ProgressModel?;
      
      print('✅ تم تحميل الدرس بنجاح');
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في تحميل الدرس: $e');
      _setError('فشل في تحميل الدرس - حاول مرة أخرى');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeSlide(String userId, String lessonId, String slideId) async {
    if (_currentProgress == null) {
      _currentProgress = ProgressModel(lessonId: lessonId);
    }

    try {
      final updatedSlidesCompleted = List<String>.from(_currentProgress!.slidesCompleted);
      if (!updatedSlidesCompleted.contains(slideId)) {
        updatedSlidesCompleted.add(slideId);
        
        _currentProgress = _currentProgress!.copyWith(
          slidesCompleted: updatedSlidesCompleted,
        );
        
        // حفظ التقدم مع timeout
        await FirebaseService.updateLessonProgress(userId, lessonId, _currentProgress!)
            .timeout(const Duration(seconds: 10));
        
        // Award XP for completing slide with timeout
        try {
          await FirebaseService.addXPAndGems(userId, 10, 1, 'إكمال شريحة')
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          print('⚠️ فشل في منح المكافآت: $e');
          // لا نفشل العملية بسبب هذا الخطأ
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('❌ خطأ في حفظ تقدم الشريحة: $e');
      _setError('فشل في حفظ التقدم - حاول مرة أخرى');
    }
  }

  Future<void> completeLesson(String userId, String lessonId) async {
    if (_currentLesson == null) return;

    try {
      final completedProgress = _currentProgress?.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      ) ?? ProgressModel(
        lessonId: lessonId,
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      // حفظ التقدم مع timeout
      await FirebaseService.updateLessonProgress(userId, lessonId, completedProgress)
          .timeout(const Duration(seconds: 10));
      
      // Update user's completed lessons with timeout
      await FirebaseService.updateUserData(userId, {
        'completedLessons': FieldValue.arrayUnion([lessonId]),
      }).timeout(const Duration(seconds: 10));
      
      // Award XP and gems for completing lesson with timeout
      try {
        await FirebaseService.addXPAndGems(
          userId, 
          _currentLesson!.xpReward, 
          _currentLesson!.gemsReward, 
          'إكمال درس: ${_currentLesson!.title}'
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        print('⚠️ فشل في منح مكافآت إكمال الدرس: $e');
        // لا نفشل العملية بسبب هذا الخطأ
      }
      
      _currentProgress = completedProgress;
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في إكمال الدرس: $e');
      _setError('فشل في حفظ إكمال الدرس - حاول مرة أخرى');
    }
  }

  Future<void> saveQuizResult(String userId, String lessonId, QuizResultModel result) async {
    try {
      // حفظ نتيجة الاختبار مع timeout
      await FirebaseService.saveQuizResult(userId, lessonId, result)
          .timeout(const Duration(seconds: 10));
      
      // Award XP and gems based on quiz performance with timeout
      int xpReward = 100;
      int gemsReward = 5;
      
      if (result.score >= 90) {
        xpReward += 50; // Bonus for excellent performance
        gemsReward += 3;
      } else if (result.score >= 80) {
        xpReward += 25;
        gemsReward += 2;
      }
      
      try {
        await FirebaseService.addXPAndGems(
          userId, 
          xpReward, 
          gemsReward, 
          'إكمال اختبار: ${result.score}%'
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        print('⚠️ فشل في منح مكافآت الاختبار: $e');
        // لا نفشل العملية بسبب هذا الخطأ
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في حفظ نتيجة الاختبار: $e');
      _setError('فشل في حفظ نتيجة الاختبار - حاول مرة أخرى');
    }
  }

  List<LessonModel> getAvailableLessons(List<String> completedLessons, int currentLevel) {
    print('🔍 البحث عن الدروس المتاحة...');
    print('📚 إجمالي الدروس: ${_lessons.length}');
    print('🎯 المستوى الحالي: $currentLevel');
    print('✅ الدروس المكتملة: ${completedLessons.length}');
    
    if (_lessons.isEmpty) {
      print('⚠️ لا توجد دروس محملة - قم بتحديث القائمة');
      return [];
    }
    
    final availableLessons = _lessons.where((lesson) {
      // Show current level lessons and next level if current is completed
      if (lesson.level == currentLevel) {
        print('  ✓ درس متاح (المستوى الحالي): ${lesson.title}');
        return true;
      }
      if (lesson.level == currentLevel + 1) {
        // Check if current level is completed
        final currentLevelLessons = _lessons.where((l) => l.level == currentLevel).toList();
        final completedCurrentLevel = currentLevelLessons.every((l) => completedLessons.contains(l.id));
        if (completedCurrentLevel) {
          print('  ✓ درس متاح (المستوى التالي): ${lesson.title}');
          return true;
        } else {
          print('  ⏳ درس مقفل (المستوى التالي): ${lesson.title}');
        }
      } else {
        print('  🔒 درس غير متاح (مستوى ${lesson.level}): ${lesson.title}');
      }
      return false;
    }).toList();
    
    print('🎯 الدروس المتاحة: ${availableLessons.length}');
    return availableLessons;
  }

  Future<LessonModel?> getLessonById(String lessonId) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🔍 البحث عن الدرس: $lessonId');
      
      final lesson = await FirebaseService.getLesson(lessonId)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('انتهت مهلة تحميل الدرس');
      });
      
      if (lesson != null) {
        print('✅ تم العثور على الدرس: ${lesson.title}');
      } else {
        print('❌ لم يتم العثور على الدرس');
      }
      
      return lesson;
    } catch (e) {
      print('❌ خطأ في تحميل الدرس: $e');
      _setError('فشل في تحميل الدرس - تحقق من الاتصال وحاول مرة أخرى');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> retryLoadLessons({int? level}) async {
    print('🔄 إعادة محاولة تحميل الدروس...');
    await loadLessons(level: level);
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
