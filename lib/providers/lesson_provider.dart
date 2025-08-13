import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  
  Set<String> _localCompletedLessons = {};
  Map<String, int> _localLessonXP = {};
  Map<String, int> _localLessonGems = {};

  List<LessonModel> get lessons => _lessons;
  List<LessonModel> get localLessons => _localLessons;
  LessonModel? get currentLesson => _currentLesson;
  ProgressModel? get currentProgress => _currentProgress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNetworkConnection => _hasNetworkConnection;

  /// تحميل فوري للدروس مع أولوية للمحتوى المحلي
  Future<void> loadLessons({int? level, bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🚀 بدء التحميل الفوري للدروس...');
      
      // المرحلة 1: تحميل الدروس المحلية فوراً (أولوية قصوى)
      await _loadLocalLessonsInstantly(level: level);
      
      // المرحلة 2: تحميل من الكاش إذا متوفر
      if (!forceRefresh) {
        await _loadFromCacheAsync(level: level);
      }
      
      // المرحلة 3: تحميل من Firebase في الخلفية
      _loadFirebaseLessonsInBackground(level: level);
      
    } catch (e) {
      print('❌ خطأ في تحميل الدروس: $e');
      _setError('فشل في تحميل الدروس');
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل الدروس المحلية فوراً
  Future<void> _loadLocalLessonsInstantly({int? level}) async {
    try {
      print('⚡ تحميل الدروس المحلية فوراً...');
      
      _localLessons = await LocalService.getLocalLessons(level: level);
      _lessons = List.from(_localLessons);
      
      // تحميل التقدم المحلي
      await _loadLocalProgress();
      
      print('✅ تم تحميل ${_lessons.length} درس محلي فوراً');
      
      // إشعار فوري لعرض الدروس
      notifyListeners();
      
    } catch (e) {
      print('⚠️ خطأ في تحميل الدروس المحلية: $e');
      _localLessons = [];
      _lessons = [];
    }
  }

  /// تحميل من الكاش بشكل غير متزامن
  Future<void> _loadFromCacheAsync({int? level}) async {
    try {
      final cachedLessons = await CacheService.getCachedLessons(level: level);
      final cacheAge = await CacheService.getCacheAge();
      
      if (cachedLessons.isNotEmpty && cacheAge != null && 
          DateTime.now().difference(cacheAge).inMinutes < 30) {
        
        // دمج الدروس المحلية مع المخزنة
        final allLessons = <LessonModel>[];
        allLessons.addAll(_localLessons);
        
        for (var lesson in cachedLessons) {
          if (!allLessons.any((l) => l.id == lesson.id)) {
            allLessons.add(lesson);
          }
        }
        
        _lessons = allLessons;
        _lastCacheUpdate = cacheAge;
        
        print('💾 تم دمج ${cachedLessons.length} درس من الكاش');
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ خطأ في تحميل الكاش: $e');
    }
  }

  /// تحميل دروس Firebase في الخلفية
  Future<void> _loadFirebaseLessonsInBackground({int? level}) async {
    try {
      print('☁️ تحميل دروس Firebase في الخلفية...');
      
      _hasNetworkConnection = await FirebaseService.checkConnection()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      
      if (!_hasNetworkConnection) {
        print('📱 وضع أوفلاين - الاعتماد على الدروس المحلية');
        return;
      }
      
      final firebaseLessons = await FirebaseService.getLessons(level: level)
          .timeout(const Duration(seconds: 10), onTimeout: () => <LessonModel>[]);
      
      if (firebaseLessons.isNotEmpty) {
        // دمج جميع الدروس
        final allLessons = <LessonModel>[];
        allLessons.addAll(_localLessons);
        
        for (var lesson in firebaseLessons) {
          if (!allLessons.any((l) => l.id == lesson.id)) {
            allLessons.add(lesson);
          }
        }
        
        // ترتيب الدروس
        allLessons.sort((a, b) {
          if (a.level != b.level) return a.level.compareTo(b.level);
          return a.order.compareTo(b.order);
        });
        
        _lessons = allLessons;
        
        // حفظ في الكاش
        await CacheService.cacheLessons(_lessons);
        _lastCacheUpdate = DateTime.now();
        
        print('✅ تم دمج ${firebaseLessons.length} درس من Firebase');
        notifyListeners();
      }
      
    } catch (e) {
      print('⚠️ خطأ في تحميل دروس Firebase: $e');
    }
  }

  /// إكمال درس محلياً مع تحديث فوري للـ XP والجواهر
  Future<void> completeLessonLocally(String userId, String lessonId, int xpReward, int gemsReward) async {
    try {
      // إضافة للدروس المكتملة محلياً
      _localCompletedLessons.add(lessonId);
      _localLessonXP[lessonId] = xpReward;
      _localLessonGems[lessonId] = gemsReward;
      
      // حفظ التقدم محلياً
      await _saveLocalProgress();
      
      print('💎 تم إكمال الدرس محلياً: +$xpReward XP, +$gemsReward جوهرة');
      
      // إشعار فوري
      notifyListeners();
      
      // مزامنة مع Firebase في الخلفية
      _syncLessonCompletionWithFirebase(userId, lessonId, xpReward, gemsReward);
      
    } catch (e) {
      print('❌ خطأ في إكمال الدرس محلياً: $e');
    }
  }

  /// إكمال اختبار محلياً مع تحديث فوري للـ XP والجواهر
  Future<void> completeQuizLocally(String userId, String lessonId, int score) async {
    try {
      int xpReward = 100;
      int gemsReward = 5;
      
      // مكافآت إضافية حسب النتيجة
      if (score >= 90) {
        xpReward += 50;
        gemsReward += 3;
      } else if (score >= 80) {
        xpReward += 25;
        gemsReward += 2;
      }
      
      // حفظ النتيجة محلياً
      final quizKey = '${lessonId}_quiz';
      _localLessonXP[quizKey] = xpReward;
      _localLessonGems[quizKey] = gemsReward;
      
      await _saveLocalProgress();
      
      print('🎯 تم إكمال الاختبار محلياً: $score% (+$xpReward XP, +$gemsReward جوهرة)');
      
      // إشعار فوري
      notifyListeners();
      
      // مزامنة مع Firebase في الخلفية
      _syncQuizCompletionWithFirebase(userId, lessonId, score, xpReward, gemsReward);
      
    } catch (e) {
      print('❌ خطأ في إكمال الاختبار محلياً: $e');
    }
  }

  /// حفظ التقدم المحلي
  Future<void> _saveLocalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ الدروس المكتملة
      await prefs.setStringList('local_completed_lessons', _localCompletedLessons.toList());
      
      // حفظ XP المحلي
      final xpEntries = _localLessonXP.entries.map((e) => '${e.key}:${e.value}').toList();
      await prefs.setStringList('local_lesson_xp', xpEntries);
      
      // حفظ الجواهر المحلية
      final gemsEntries = _localLessonGems.entries.map((e) => '${e.key}:${e.value}').toList();
      await prefs.setStringList('local_lesson_gems', gemsEntries);
      
    } catch (e) {
      print('⚠️ خطأ في حفظ التقدم المحلي: $e');
    }
  }

  /// تحميل التقدم المحلي
  Future<void> _loadLocalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل الدروس المكتملة
      final completedLessons = prefs.getStringList('local_completed_lessons') ?? [];
      _localCompletedLessons = completedLessons.toSet();
      
      // تحميل XP المحلي
      final xpEntries = prefs.getStringList('local_lesson_xp') ?? [];
      _localLessonXP.clear();
      for (var entry in xpEntries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          _localLessonXP[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }
      
      // تحميل الجواهر المحلية
      final gemsEntries = prefs.getStringList('local_lesson_gems') ?? [];
      _localLessonGems.clear();
      for (var entry in gemsEntries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          _localLessonGems[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }
      
      print('📊 تم تحميل التقدم المحلي: ${_localCompletedLessons.length} درس مكتمل');
      
    } catch (e) {
      print('⚠️ خطأ في تحميل التقدم المحلي: $e');
    }
  }

  /// مزامنة إكمال الدرس مع Firebase
  Future<void> _syncLessonCompletionWithFirebase(String userId, String lessonId, int xpReward, int gemsReward) async {
    if (!_hasNetworkConnection) return;
    
    try {
      await FirebaseService.updateUserData(userId, {
        'completedLessons': FieldValue.arrayUnion([lessonId]),
      }).timeout(const Duration(seconds: 10));
      
      await FirebaseService.addXPAndGems(userId, xpReward, gemsReward, 'إكمال درس محلي')
          .timeout(const Duration(seconds: 10));
      
      print('🔄 تم مزامنة إكمال الدرس مع Firebase');
      
      // إزالة من التقدم المحلي بعد المزامنة
      _localCompletedLessons.remove(lessonId);
      _localLessonXP.remove(lessonId);
      _localLessonGems.remove(lessonId);
      await _saveLocalProgress();
      
    } catch (e) {
      print('⚠️ فشل في مزامنة إكمال الدرس: $e');
    }
  }

  /// مزامنة إكمال الاختبار مع Firebase
  Future<void> _syncQuizCompletionWithFirebase(String userId, String lessonId, int score, int xpReward, int gemsReward) async {
    if (!_hasNetworkConnection) return;
    
    try {
      final quizResult = QuizResultModel(
        lessonId: lessonId,
        userId: userId,
        score: score,
        completedAt: DateTime.now(),
        answers: [], // يمكن إضافة الإجابات لاحقاً
      );
      
      await FirebaseService.saveQuizResult(userId, lessonId, quizResult)
          .timeout(const Duration(seconds: 10));
      
      await FirebaseService.addXPAndGems(userId, xpReward, gemsReward, 'إكمال اختبار محلي: $score%')
          .timeout(const Duration(seconds: 10));
      
      print('🔄 تم مزامنة إكمال الاختبار مع Firebase');
      
      // إزالة من التقدم المحلي بعد المزامنة
      final quizKey = '${lessonId}_quiz';
      _localLessonXP.remove(quizKey);
      _localLessonGems.remove(quizKey);
      await _saveLocalProgress();
      
    } catch (e) {
      print('⚠️ فشل في مزامنة إكمال الاختبار: $e');
    }
  }

  /// الحصول على الدروس المتاحة مع دعم التقدم المحلي
  List<LessonModel> getAvailableLessons(List<String> completedLessons, int currentLevel) {
    print('🔍 البحث عن الدروس المتاحة...');
    print('📚 إجمالي الدروس: ${_lessons.length}');
    print('🎯 المستوى الحالي: $currentLevel');
    
    if (_lessons.isEmpty) {
      print('⚠️ لا توجد دروس محملة');
      return [];
    }
    
    // دمج الدروس المكتملة مع التقدم المحلي
    final allCompletedLessons = <String>{};
    allCompletedLessons.addAll(completedLessons);
    allCompletedLessons.addAll(_localCompletedLessons);
    
    final availableLessons = _lessons.where((lesson) {
      // إظهار دروس المستوى الحالي والأول دائماً
      if (lesson.level <= currentLevel || lesson.level == 1) {
        return true;
      }
      
      // منطق المستويات المتقدمة
      if (lesson.level == currentLevel + 1) {
        final currentLevelLessons = _lessons.where((l) => l.level == currentLevel).toList();
        final completedCurrentLevel = currentLevelLessons.every((l) => allCompletedLessons.contains(l.id));
        return completedCurrentLevel;
      }
      
      return false;
    }).toList();
    
    // ترتيب الدروس
    availableLessons.sort((a, b) {
      if (a.level != b.level) return a.level.compareTo(b.level);
      return a.order.compareTo(b.order);
    });
    
    print('🎯 الدروس المتاحة: ${availableLessons.length}');
    return availableLessons;
  }

  /// الحصول على إجمالي XP المحلي
  int get totalLocalXP {
    return _localLessonXP.values.fold(0, (sum, xp) => sum + xp);
  }

  /// الحصول على إجمالي الجواهر المحلية
  int get totalLocalGems {
    return _localLessonGems.values.fold(0, (sum, gems) => sum + gems);
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
