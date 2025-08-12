import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/local_service.dart';
import '../models/lesson_model.dart';
import '../models/progress_model.dart';
import '../models/quiz_result_model.dart';

class LessonProvider with ChangeNotifier {
  List<LessonModel> _lessons = [];
  List<LessonModel> _localLessons = [];
  LessonModel? _currentLesson;
  ProgressModel? _currentProgress;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasNetworkConnection = true;

  List<LessonModel> get lessons => _lessons;
  List<LessonModel> get localLessons => _localLessons;
  LessonModel? get currentLesson => _currentLesson;
  ProgressModel? get currentProgress => _currentProgress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNetworkConnection => _hasNetworkConnection;

  /// تحميل الدروس من كلا المصدرين (محلي وFirebase)
  Future<void> loadLessons({int? level}) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🔄 بدء تحميل الدروس من جميع المصادر...');
      print('📊 المستوى المطلوب: ${level ?? "جميع المستويات"}');
      
      _lessons.clear();
      
      // تحميل الدروس المحلية أولاً (دائماً متوفرة)
      await _loadLocalLessons(level: level);
      
      _lessons.addAll(_localLessons);
      print('📚 تم إضافة ${_localLessons.length} درس محلي للقائمة الرئيسية');
      
      // محاولة تحميل دروس Firebase
      await _loadFirebaseLessons(level: level);
      
      // ترتيب الدروس النهائية
      _lessons.sort((a, b) {
        if (a.level != b.level) {
          return a.level.compareTo(b.level);
        }
        return a.order.compareTo(b.order);
      });
      
      print('✅ إجمالي الدروس المحملة: ${_lessons.length}');
      
      if (_lessons.isEmpty) {
        _setError('لا توجد دروس متاحة حالياً');
      } else {
        print('📋 الدروس المحملة:');
        for (var lesson in _lessons) {
          final source = _localLessons.any((l) => l.id == lesson.id) ? '🏠' : '☁️';
          print('  $source ${lesson.title} (المستوى: ${lesson.level})');
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ خطأ عام في تحميل الدروس: $e');
      _setError('فشل في تحميل الدروس - حاول مرة أخرى لاحقاً');
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل الدروس المحلية
  Future<void> _loadLocalLessons({int? level}) async {
    try {
      print('🏠 تحميل الدروس المحلية...');
      _localLessons = await LocalService.getLocalLessons(level: level);
      print('✅ تم تحميل ${_localLessons.length} درس محلي');
    } catch (e) {
      print('⚠️ خطأ في تحميل الدروس المحلية: $e');
      _localLessons = [];
    }
  }

  /// تحميل دروس Firebase
  Future<void> _loadFirebaseLessons({int? level}) async {
    try {
      print('☁️ تحميل دروس Firebase...');
      
      // التحقق من الاتصال
      _hasNetworkConnection = await FirebaseService.checkConnection()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      
      if (!_hasNetworkConnection) {
        print('❌ لا يوجد اتصال بالإنترنت - الاعتماد على الدروس المحلية');
        return;
      }
      
      // تحميل دروس Firebase
      final firebaseLessons = await FirebaseService.getLessons(level: level)
          .timeout(const Duration(seconds: 20), onTimeout: () {
        print('⏰ انتهت مهلة تحميل دروس Firebase');
        return <LessonModel>[];
      });
      
      print('✅ تم تحميل ${firebaseLessons.length} درس من Firebase');
      
      // إضافة دروس Firebase للقائمة الرئيسية
      for (var lesson in firebaseLessons) {
        if (!_lessons.any((l) => l.id == lesson.id)) {
          _lessons.add(lesson);
        }
      }
      
    } catch (e) {
      print('⚠️ خطأ في تحميل دروس Firebase: $e');
      _hasNetworkConnection = false;
    }
  }

  /// دمج الدروس المحلية والسحابية
  void _mergeLessons() {
    // الدروس المحلية تُضاف مباشرة والـ Firebase lessons تُضاف في _loadFirebaseLessons
    print('🔄 الدروس تم دمجها بالفعل أثناء التحميل');
  }

  /// تحميل درس محدد (يبحث في المحلي أولاً ثم Firebase)
  Future<void> loadLesson(String lessonId, String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('📖 تحميل الدرس: $lessonId');
      
      // البحث في الدروس المحلية أولاً
      _currentLesson = await LocalService.getLocalLesson(lessonId);
      
      if (_currentLesson == null && _hasNetworkConnection) {
        // البحث في Firebase إذا لم يوجد محلياً
        print('🔍 البحث في Firebase...');
        _currentLesson = await FirebaseService.getLesson(lessonId)
            .timeout(const Duration(seconds: 10));
      }
      
      if (_currentLesson != null) {
        // تحميل التقدم من Firebase (إذا متوفر)
        if (_hasNetworkConnection) {
          try {
            _currentProgress = await FirebaseService.getLessonProgress(userId, lessonId)
                .timeout(const Duration(seconds: 10));
          } catch (e) {
            print('⚠️ فشل في تحميل التقدم: $e');
            _currentProgress = null;
          }
        }
        
        print('✅ تم تحميل الدرس: ${_currentLesson!.title}');
      } else {
        print('❌ لم يتم العثور على الدرس');
        _setError('لم يتم العثور على الدرس المطلوب');
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في تحميل الدرس: $e');
      _setError('فشل في تحميل الدرس - حاول مرة أخرى');
    } finally {
      _setLoading(false);
    }
  }

  /// البحث عن درس بالمعرف (يبحث في المحلي أولاً)
  Future<LessonModel?> getLessonById(String lessonId) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🔍 البحث عن الدرس: $lessonId');
      
      // البحث في الدروس المحلية أولاً
      var lesson = await LocalService.getLocalLesson(lessonId);
      
      if (lesson == null && _hasNetworkConnection) {
        // البحث في Firebase
        lesson = await FirebaseService.getLesson(lessonId)
            .timeout(const Duration(seconds: 10), onTimeout: () => null);
      }
      
      if (lesson != null) {
        print('✅ تم العثور على الدرس: ${lesson.title}');
      } else {
        print('❌ لم يتم العثور على الدرس');
      }
      
      return lesson;
    } catch (e) {
      print('❌ خطأ في البحث عن الدرس: $e');
      _setError('فشل في البحث عن الدرس');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// إعادة تحميل الدروس
  Future<void> retryLoadLessons({int? level}) async {
    print('🔄 إعادة محاولة تحميل الدروس...');
    await loadLessons(level: level);
  }

  /// تحميل الدروس المحلية فقط (للاستخدام الأوفلاين)
  Future<void> loadOfflineLessons({int? level}) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🏠 تحميل الدروس المحلية فقط...');
      
      _localLessons = await LocalService.getLocalLessons(level: level);
      _lessons = List.from(_localLessons);
      
      print('✅ تم تحميل ${_lessons.length} درس محلي');
      
      if (_lessons.isEmpty) {
        _setError('لا توجد دروس محلية متاحة');
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في تحميل الدروس المحلية: $e');
      _setError('فشل في تحميل الدروس المحلية');
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
        
        // حفظ التقدم في Firebase (إذا متوفر)
        if (_hasNetworkConnection) {
          try {
            await FirebaseService.updateLessonProgress(userId, lessonId, _currentProgress!)
                .timeout(const Duration(seconds: 10));
            
            await FirebaseService.addXPAndGems(userId, 10, 1, 'إكمال شريحة')
                .timeout(const Duration(seconds: 5));
          } catch (e) {
            print('⚠️ فشل في حفظ التقدم أونلاين: $e');
            // يمكن إضافة حفظ محلي هنا لاحقاً
          }
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

      // حفظ في Firebase (إذا متوفر)
      if (_hasNetworkConnection) {
        try {
          await FirebaseService.updateLessonProgress(userId, lessonId, completedProgress)
              .timeout(const Duration(seconds: 10));
          
          await FirebaseService.updateUserData(userId, {
            'completedLessons': FieldValue.arrayUnion([lessonId]),
          }).timeout(const Duration(seconds: 10));
          
          await FirebaseService.addXPAndGems(
            userId, 
            _currentLesson!.xpReward, 
            _currentLesson!.gemsReward, 
            'إكمال درس: ${_currentLesson!.title}'
          ).timeout(const Duration(seconds: 10));
        } catch (e) {
          print('⚠️ فشل في حفظ إكمال الدرس أونلاين: $e');
        }
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
      // حفظ في Firebase (إذا متوفر)
      if (_hasNetworkConnection) {
        try {
          await FirebaseService.saveQuizResult(userId, lessonId, result)
              .timeout(const Duration(seconds: 10));
          
          int xpReward = 100;
          int gemsReward = 5;
          
          if (result.score >= 90) {
            xpReward += 50;
            gemsReward += 3;
          } else if (result.score >= 80) {
            xpReward += 25;
            gemsReward += 2;
          }
          
          await FirebaseService.addXPAndGems(
            userId, 
            xpReward, 
            gemsReward, 
            'إكمال اختبار: ${result.score}%'
          ).timeout(const Duration(seconds: 10));
        } catch (e) {
          print('⚠️ فشل في حفظ نتيجة الاختبار أونلاين: $e');
        }
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
      if (lesson.level == currentLevel) {
        print('  ✓ درس متاح (المستوى الحالي): ${lesson.title}');
        return true;
      }
      if (lesson.level == currentLevel + 1) {
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
