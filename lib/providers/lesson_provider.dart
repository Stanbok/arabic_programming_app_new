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
  Future<void> loadLessons({int? unit, bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();
      
      // المرحلة 1: تحميل الدروس المحلية فوراً (أولوية قصوى)
      await _loadLocalLessonsInstantly(unit: unit);
      
      // المرحلة 2: تحميل من الكاش إذا متوفر
      if (!forceRefresh) {
        await _loadFromCacheAsync(unit: unit);
      }
      
      // المرحلة 3: تحميل من Firebase في الخلفية
      _loadFirebaseLessonsInBackground(unit: unit);
      
    } catch (e) {
      _setError('فشل في تحميل الدروس');
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل الدروس المحلية فوراً
  Future<void> _loadLocalLessonsInstantly({int? unit}) async {
    try {
      _localLessons = await LocalService.getLocalLessons(unit: unit);
      _lessons = List.from(_localLessons);
      
      // تحميل التقدم المحلي
      await _loadLocalProgress();
      
      // إشعار فوري لعرض الدروس
      notifyListeners();
      
    } catch (e) {
      _localLessons = [];
      _lessons = [];
    }
  }

  /// تحميل من الكاش بشكل غير متزامن
  Future<void> _loadFromCacheAsync({int? unit}) async {
    try {
      final cachedLessons = await CacheService.getCachedLessons(unit: unit);
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
        
        notifyListeners();
      }
    } catch (e) {
      // تجاهل أخطاء الكاش
    }
  }

  /// تحميل دروس Firebase في الخلفية
  Future<void> _loadFirebaseLessonsInBackground({int? unit}) async {
    try {
      _hasNetworkConnection = await FirebaseService.checkConnection()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      
      if (!_hasNetworkConnection) {
        return;
      }
      
      final firebaseLessons = await FirebaseService.getLessons(unit: unit)
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
        
        // ترتيب الدروس حسب الوحدة والترتيب
        allLessons.sort((a, b) {
          if (a.unit != b.unit) return a.unit.compareTo(b.unit);
          return a.order.compareTo(b.order);
        });
        
        _lessons = allLessons;
        
        // حفظ في الكاش
        await CacheService.cacheLessons(_lessons);
        _lastCacheUpdate = DateTime.now();
        
        notifyListeners();
      }
      
    } catch (e) {
      // تجاهل أخطاء Firebase
    }
  }

  /// الحصول على الدروس المتاحة بناءً على نظام الوحدات - متاح لجميع المستخدمين
  List<LessonModel> getAvailableLessons(List<String> completedLessons, int currentUnit) {
    if (_lessons.isEmpty) {
      return [];
    }
    
    // دمج الدروس المكتملة مع التقدم المحلي
    final allCompletedLessons = <String>{};
    allCompletedLessons.addAll(completedLessons);
    allCompletedLessons.addAll(_localCompletedLessons);
    
    // الحصول على الوحدة الحالية للمستخدم
    int userCurrentUnit = _getUserCurrentUnit(allCompletedLessons);
    
    final availableLessons = _lessons.where((lesson) {
      // عرض دروس الوحدة الحالية فقط
      return lesson.unit == userCurrentUnit;
    }).toList();
    
    // ترتيب الدروس حسب الترتيب
    availableLessons.sort((a, b) => a.order.compareTo(b.order));
    
    return availableLessons;
  }

  /// تحديد الوحدة الحالية للمستخدم
  int _getUserCurrentUnit(Set<String> completedLessons) {
    if (_lessons.isEmpty) return 1;
    
    // الحصول على جميع الوحدات المتاحة
    final availableUnits = _lessons.map((l) => l.unit).toSet().toList()..sort();
    
    for (int unit in availableUnits) {
      // الحصول على دروس هذه الوحدة
      final unitLessons = _lessons.where((l) => l.unit == unit).toList();
      
      // التحقق من إكمال جميع دروس الوحدة
      final completedInUnit = unitLessons.where((l) => completedLessons.contains(l.id)).length;
      
      // إذا لم تكتمل الوحدة، فهي الوحدة الحالية
      if (completedInUnit < unitLessons.length) {
        return unit;
      }
    }
    
    // إذا اكتملت جميع الوحدات، عرض الوحدة التالية إن وجدت
    final maxUnit = availableUnits.isNotEmpty ? availableUnits.last : 1;
    return maxUnit + 1;
  }

  /// الحصول على معلومات الوحدات للعرض مع الانيميشن
  List<UnitInfo> getUnitsInfo(List<String> completedLessons) {
    if (_lessons.isEmpty) return [];
    
    final allCompletedLessons = <String>{};
    allCompletedLessons.addAll(completedLessons);
    allCompletedLessons.addAll(_localCompletedLessons);
    
    final availableUnits = _lessons.map((l) => l.unit).toSet().toList()..sort();
    final unitsInfo = <UnitInfo>[];
    
    for (int unit in availableUnits) {
      final unitLessons = _lessons.where((l) => l.unit == unit).toList();
      final completedCount = unitLessons.where((l) => allCompletedLessons.contains(l.id)).length;
      final isCompleted = completedCount == unitLessons.length;
      final isUnlocked = unit == 1 || (unit > 1 && unitsInfo.isNotEmpty && unitsInfo.last.isCompleted);
      
      unitsInfo.add(UnitInfo(
        unit: unit,
        title: _getUnitTitle(unit),
        totalLessons: unitLessons.length,
        completedLessons: completedCount,
        isCompleted: isCompleted,
        isUnlocked: isUnlocked,
        lessons: isUnlocked ? unitLessons : [],
      ));
    }
    
    return unitsInfo;
  }

  /// الحصول على عنوان الوحدة
  String _getUnitTitle(int unit) {
    switch (unit) {
      case 1:
        return 'أساسيات Python';
      case 2:
        return 'البرمجة المتقدمة';
      case 3:
        return 'المشاريع العملية';
      default:
        return 'الوحدة $unit';
    }
  }

  // ... باقي الدوال تبقى كما هي مع تغيير level إلى unit حيث لزم الأمر ...

  /// إكمال درس محلياً مع تحديث فوري للـ XP والجواهر
  Future<void> completeLessonLocally(String userId, String lessonId, int xpReward, int gemsReward, Function(int, int, String) addXPCallback) async {
    try {
      _localCompletedLessons.add(lessonId);
      _localLessonXP[lessonId] = xpReward;
      _localLessonGems[lessonId] = gemsReward;
      
      await _saveLocalProgress();
      await addXPCallback(xpReward, gemsReward, 'إكمال درس محلي');
      
      notifyListeners();
      _syncLessonCompletionWithFirebase(userId, lessonId, xpReward, gemsReward);
      
    } catch (e) {
      print('خطأ في إكمال الدرس محلياً: $e');
    }
  }

  /// إكمال اختبار محلياً مع تحديث فوري للـ XP والجواهر
  Future<void> completeQuizLocally(String userId, String lessonId, int score, Function(int, int, String) addXPCallback) async {
    try {
      int xpReward = 100;
      int gemsReward = 5;
      
      if (score >= 90) {
        xpReward += 50;
        gemsReward += 3;
      } else if (score >= 80) {
        xpReward += 25;
        gemsReward += 2;
      }
      
      final quizKey = '${lessonId}_quiz';
      _localLessonXP[quizKey] = xpReward;
      _localLessonGems[quizKey] = gemsReward;
      
      await _saveLocalProgress();
      await addXPCallback(xpReward, gemsReward, 'إكمال اختبار محلي: $score%');
      
      notifyListeners();
      _syncQuizCompletionWithFirebase(userId, lessonId, score, xpReward, gemsReward);
      
    } catch (e) {
      print('خطأ في إكمال الاختبار محلياً: $e');
    }
  }

  // ... باقي الدوال المساعدة تبقى كما هي ...

  Future<void> _saveLocalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_completed_lessons', _localCompletedLessons.toList());
      
      final xpEntries = _localLessonXP.entries.map((e) => '${e.key}:${e.value}').toList();
      await prefs.setStringList('local_lesson_xp', xpEntries);
      
      final gemsEntries = _localLessonGems.entries.map((e) => '${e.key}:${e.value}').toList();
      await prefs.setStringList('local_lesson_gems', gemsEntries);
    } catch (e) {
      // تجاهل أخطاء الحفظ
    }
  }

  Future<void> _loadLocalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final completedLessons = prefs.getStringList('local_completed_lessons') ?? [];
      _localCompletedLessons = completedLessons.toSet();
      
      final xpEntries = prefs.getStringList('local_lesson_xp') ?? [];
      _localLessonXP.clear();
      for (var entry in xpEntries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          _localLessonXP[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }
      
      final gemsEntries = prefs.getStringList('local_lesson_gems') ?? [];
      _localLessonGems.clear();
      for (var entry in gemsEntries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          _localLessonGems[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }
    } catch (e) {
      // تجاهل أخطاء التحميل
    }
  }

  Future<void> _syncLessonCompletionWithFirebase(String userId, String lessonId, int xpReward, int gemsReward) async {
    if (!_hasNetworkConnection) return;
    
    try {
      await FirebaseService.updateUserData(userId, {
        'completedLessons': FieldValue.arrayUnion([lessonId]),
      }).timeout(const Duration(seconds: 10));
      
      await FirebaseService.addXPAndGems(userId, xpReward, gemsReward, 'إكمال درس محلي')
          .timeout(const Duration(seconds: 10));
      
      _localCompletedLessons.remove(lessonId);
      _localLessonXP.remove(lessonId);
      _localLessonGems.remove(lessonId);
      await _saveLocalProgress();
    } catch (e) {
      // تجاهل أخطاء المزامنة
    }
  }

  Future<void> _syncQuizCompletionWithFirebase(String userId, String lessonId, int score, int xpReward, int gemsReward) async {
    if (!_hasNetworkConnection) return;
    
    try {
      final quizResult = QuizResultModel(
        lessonId: lessonId,
        score: score,
        correctAnswers: (score * 10 / 100).round(),
        totalQuestions: 10,
        answers: [],
        completedAt: DateTime.now(),
      );
      
      await FirebaseService.saveQuizResult(userId, lessonId, quizResult)
          .timeout(const Duration(seconds: 10));
      
      await FirebaseService.addXPAndGems(userId, xpReward, gemsReward, 'إكمال اختبار محلي: $score%')
          .timeout(const Duration(seconds: 10));
      
      final quizKey = '${lessonId}_quiz';
      _localLessonXP.remove(quizKey);
      _localLessonGems.remove(quizKey);
      await _saveLocalProgress();
    } catch (e) {
      // تجاهل أخطاء المزامنة
    }
  }

  int get totalLocalXP => _localLessonXP.values.fold(0, (sum, xp) => sum + xp);
  int get totalLocalGems => _localLessonGems.values.fold(0, (sum, gems) => sum + gems);

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

/// معلومات الوحدة للعرض
class UnitInfo {
  final int unit;
  final String title;
  final int totalLessons;
  final int completedLessons;
  final bool isCompleted;
  final bool isUnlocked;
  final List<LessonModel> lessons;

  UnitInfo({
    required this.unit,
    required this.title,
    required this.totalLessons,
    required this.completedLessons,
    required this.isCompleted,
    required this.isUnlocked,
    required this.lessons,
  });

  double get progress => totalLessons > 0 ? completedLessons / totalLessons : 0.0;
}
