import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/local_service.dart';
import '../services/cache_service.dart';
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
  DateTime? _lastCacheUpdate;

  List<LessonModel> get lessons => _lessons;
  List<LessonModel> get localLessons => _localLessons;
  LessonModel? get currentLesson => _currentLesson;
  ProgressModel? get currentProgress => _currentProgress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNetworkConnection => _hasNetworkConnection;

  /// تحميل الدروس مع نظام الكاش الذكي
  Future<void> loadLessons({int? level, bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🔄 بدء تحميل الدروس الذكي...');
      print('📊 المستوى المطلوب: ${level ?? "جميع المستويات"}');
      print('🔄 فرض التحديث: $forceRefresh');
      
      // المرحلة 1: تحميل من الكاش إذا متوفر وحديث
      if (!forceRefresh && await _loadFromCache(level: level)) {
        print('⚡ تم التحميل من الكاش');
        notifyListeners();
        return;
      }
      
      _lessons.clear();
      
      // المرحلة 2: تحميل الدروس المحلية (فوري)
      await _loadLocalLessonsAsync(level: level);
      
      // المرحلة 3: تحميل من Firebase بشكل متوازي
      _loadFirebaseLessonsAsync(level: level);
      
    } catch (e) {
      print('❌ خطأ عام في تحميل الدروس: $e');
      _setError('فشل في تحميل الدروس - حاول مرة أخرى لاحقاً');
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل من الكاش
  Future<bool> _loadFromCache({int? level}) async {
    try {
      final cachedLessons = await CacheService.getCachedLessons(level: level);
      final cacheAge = await CacheService.getCacheAge();
      
      // استخدام الكاش إذا كان عمره أقل من 30 دقيقة
      if (cachedLessons.isNotEmpty && cacheAge != null && 
          DateTime.now().difference(cacheAge).inMinutes < 30) {
        
        _lessons = cachedLessons;
        _lastCacheUpdate = cacheAge;
        print('✅ تم تحميل ${_lessons.length} درس من الكاش');
        return true;
      }
      
      return false;
    } catch (e) {
      print('⚠️ خطأ في تحميل الكاش: $e');
      return false;
    }
  }

  /// تحميل الدروس المحلية بشكل غير متزامن
  Future<void> _loadLocalLessonsAsync({int? level}) async {
    try {
      print('🏠 تحميل الدروس المحلية...');
      _localLessons = await LocalService.getLocalLessons(level: level);
      
      // إضافة الدروس المحلية فوراً
      _lessons.addAll(_localLessons);
      print('✅ تم إضافة ${_localLessons.length} درس محلي');
      
      // إشعار فوري لعرض الدروس المحلية
      notifyListeners();
      
    } catch (e) {
      print('⚠️ خطأ في تحميل الدروس المحلية: $e');
      _localLessons = [];
    }
  }

  /// تحميل دروس Firebase بشكل غير متزامن
  Future<void> _loadFirebaseLessonsAsync({int? level}) async {
    try {
      print('☁️ تحميل دروس Firebase في الخلفية...');
      
      // التحقق من الاتصال
      _hasNetworkConnection = await FirebaseService.checkConnection()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      
      if (!_hasNetworkConnection) {
        print('❌ لا يوجد اتصال بالإنترنت - الاعتماد على الدروس المحلية');
        return;
      }
      
      // تحميل دروس Firebase
      final firebaseLessons = await FirebaseService.getLessons(level: level)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        print('⏰ انتهت مهلة تحميل دروس Firebase');
        return <LessonModel>[];
      });
      
      if (firebaseLessons.isNotEmpty) {
        print('✅ تم تحميل ${firebaseLessons.length} درس من Firebase');
        
        // دمج دروس Firebase مع المحلية
        final allLessons = <LessonModel>[];
        allLessons.addAll(_localLessons);
        
        for (var lesson in firebaseLessons) {
          if (!allLessons.any((l) => l.id == lesson.id)) {
            allLessons.add(lesson);
          }
        }
        
        // ترتيب الدروس
        allLessons.sort((a, b) {
          if (a.level != b.level) {
            return a.level.compareTo(b.level);
          }
          return a.order.compareTo(b.order);
        });
        
        _lessons = allLessons;
        
        // حفظ في الكاش
        await CacheService.cacheLessons(_lessons);
        _lastCacheUpdate = DateTime.now();
        
        print('💾 تم حفظ ${_lessons.length} درس في الكاش');
        
        // إشعار بالتحديث
        notifyListeners();
      }
      
    } catch (e) {
      print('⚠️ خطأ في تحميل دروس Firebase: $e');
      _hasNetworkConnection = false;
    }
  }

  /// تحميل درس محدد مع الكاش
  Future<void> loadLesson(String lessonId, String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('📖 تحميل الدرس: $lessonId');
      
      // البحث في الكاش أولاً
      _currentLesson = await CacheService.getCachedLesson(lessonId);
      
      if (_currentLesson == null) {
        // البحث في الدروس المحلية
        _currentLesson = await LocalService.getLocalLesson(lessonId);
      }
      
      if (_currentLesson == null && _hasNetworkConnection) {
        // البحث في Firebase
        print('🔍 البحث في Firebase...');
        _currentLesson = await FirebaseService.getLesson(lessonId)
            .timeout(const Duration(seconds: 10));
        
        // حفظ في الكاش
        if (_currentLesson != null) {
          await CacheService.cacheLesson(_currentLesson!);
        }
      }
      
      if (_currentLesson != null) {
        // تحميل التقدم
        await _loadLessonProgress(userId, lessonId);
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

  /// تحميل تقدم الدرس
  Future<void> _loadLessonProgress(String userId, String lessonId) async {
    if (_hasNetworkConnection) {
      try {
        _currentProgress = await FirebaseService.getLessonProgress(userId, lessonId)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        print('⚠️ فشل في تحميل التقدم: $e');
        _currentProgress = null;
      }
    }
  }

  /// البحث عن درس بالمعرف مع الكاش
  Future<LessonModel?> getLessonById(String lessonId) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🔍 البحث عن الدرس: $lessonId');
      
      // البحث في الكاش أولاً
      var lesson = await CacheService.getCachedLesson(lessonId);
      
      if (lesson == null) {
        // البحث في الدروس المحلية
        lesson = await LocalService.getLocalLesson(lessonId);
      }
      
      if (lesson == null && _hasNetworkConnection) {
        // البحث في Firebase
        lesson = await FirebaseService.getLesson(lessonId)
            .timeout(const Duration(seconds: 10), onTimeout: () => null);
        
        // حفظ في الكاش
        if (lesson != null) {
          await CacheService.cacheLesson(lesson);
        }
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

  /// إكمال شريحة مع تحديث فوري للـ XP والجواهر
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
        
        // إشعار فوري
        notifyListeners();
        
        // حفظ التقدم في Firebase (في الخلفية)
        _saveSlideProgressAsync(userId, lessonId, slideId);
      }
    } catch (e) {
      print('❌ خطأ في حفظ تقدم الشريحة: $e');
      _setError('فشل في حفظ التقدم - حاول مرة أخرى');
    }
  }

  /// حفظ تقدم الشريحة بشكل غير متزامن
  Future<void> _saveSlideProgressAsync(String userId, String lessonId, String slideId) async {
    if (_hasNetworkConnection) {
      try {
        await FirebaseService.updateLessonProgress(userId, lessonId, _currentProgress!)
            .timeout(const Duration(seconds: 10));
        
        await FirebaseService.addXPAndGems(userId, 10, 1, 'إكمال شريحة')
            .timeout(const Duration(seconds: 5));
        
        print('✅ تم حفظ تقدم الشريحة أونلاين');
      } catch (e) {
        print('⚠️ فشل في حفظ التقدم أونلاين: $e');
        // يمكن إضافة قائمة انتظار للمزامنة لاحقاً
      }
    }
  }

  /// إكمال درس مع تحديث فوري للـ XP والجواهر
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

      _currentProgress = completedProgress;
      
      // إشعار فوري
      notifyListeners();
      
      // حفظ في Firebase (في الخلفية)
      _saveLessonCompletionAsync(userId, lessonId);
      
    } catch (e) {
      print('❌ خطأ في إكمال الدرس: $e');
      _setError('فشل في حفظ إكمال الدرس - حاول مرة أخرى');
    }
  }

  /// حفظ إكمال الدرس بشكل غير متزامن
  Future<void> _saveLessonCompletionAsync(String userId, String lessonId) async {
    if (_hasNetworkConnection) {
      try {
        await FirebaseService.updateLessonProgress(userId, lessonId, _currentProgress!)
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
        
        print('✅ تم حفظ إكمال الدرس أونلاين');
      } catch (e) {
        print('⚠️ فشل في حفظ إكمال الدرس أونلاين: $e');
      }
    }
  }

  /// حفظ نتيجة الاختبار مع تحديث فوري للـ XP والجواهر
  Future<void> saveQuizResult(String userId, String lessonId, QuizResultModel result) async {
    try {
      // إشعار فوري
      notifyListeners();
      
      // حفظ في Firebase (في الخلفية)
      _saveQuizResultAsync(userId, lessonId, result);
      
    } catch (e) {
      print('❌ خطأ في حفظ نتيجة الاختبار: $e');
      _setError('فشل في حفظ نتيجة الاختبار - حاول مرة أخرى');
    }
  }

  /// حفظ نتيجة الاختبار بشكل غير متزامن
  Future<void> _saveQuizResultAsync(String userId, String lessonId, QuizResultModel result) async {
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
        
        print('✅ تم حفظ نتيجة الاختبار أونلاين');
      } catch (e) {
        print('⚠️ فشل في حفظ نتيجة الاختبار أونلاين: $e');
      }
    }
  }

  /// الحصول على الدروس المتاحة
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
      // إظهار دروس المستوى الحالي والمستوى الأول دائماً
      if (lesson.level <= currentLevel || lesson.level == 1) {
        print('  ✓ درس متاح: ${lesson.title} (المستوى: ${lesson.level})');
        return true;
      }
      
      // منطق المستويات المتقدمة
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

  /// إعادة تحميل الدروس
  Future<void> retryLoadLessons({int? level}) async {
    print('🔄 إعادة محاولة تحميل الدروس...');
    await loadLessons(level: level, forceRefresh: true);
  }

  /// تحميل الدروس المحلية فقط
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

  /// مسح الكاش
  Future<void> clearCache() async {
    try {
      await CacheService.clearCache();
      _lastCacheUpdate = null;
      print('🗑️ تم مسح الكاش');
    } catch (e) {
      print('⚠️ خطأ في مسح الكاش: $e');
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
