import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/firebase_service.dart';
import '../services/local_service.dart';
import '../services/cache_service.dart';
import '../services/quiz_engine.dart';
import '../models/lesson_model.dart';
import '../models/quiz_result_model.dart';
import '../models/decay_tracker_model.dart';
import '../models/enhanced_quiz_result.dart';
import 'dart:math' as math;

class LessonProvider with ChangeNotifier {
  List<LessonModel> _lessons = [];
  List<LessonModel> _localLessons = [];
  LessonModel? _currentLesson;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasNetworkConnection = true;
  DateTime? _lastCacheUpdate;
  
  Set<String> _localCompletedQuizzes = {};
  Map<String, DecayTrackerModel> _decayTrackers = {};
  
  final Map<String, LessonModel> _lessonCache = {};
  final Map<int, List<LessonModel>> _unitLessonsCache = {};

  Map<String, List<EnhancedQuizResult>> _quizHistory = {};
  Map<String, UserPerformanceStats> _performanceStats = {};

  List<LessonModel> get lessons => _lessons;
  List<LessonModel> get localLessons => _localLessons;
  LessonModel? get currentLesson => _currentLesson;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNetworkConnection => _hasNetworkConnection;

  Future<void> loadLessons({int? unit, bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();
      
      // فحص الكاش في الذاكرة أولاً
      if (!forceRefresh && _isCacheValid(unit)) {
        _setLoading(false);
        return;
      }
      
      // تحميل متوازي للمحتوى المحلي والمخزن
      final futures = <Future>[
        _loadLocalLessonsOptimized(unit: unit),
        if (!forceRefresh) _loadFromCacheOptimized(unit: unit),
      ];
      
      await Future.wait(futures);
      
      // تحميل Firebase في الخلفية بدون انتظار
      _loadFirebaseLessonsInBackground(unit: unit);
      
    } catch (e) {
      _setError('فشل في تحميل الدروس');
    } finally {
      _setLoading(false);
    }
  }

  bool _isCacheValid(int? unit) {
    if (unit != null) {
      return _unitLessonsCache.containsKey(unit) && 
             _unitLessonsCache[unit]!.isNotEmpty;
    }
    return _lessons.isNotEmpty && _lastCacheUpdate != null &&
           DateTime.now().difference(_lastCacheUpdate!).inMinutes < 15;
  }

  Future<void> _loadLocalLessonsOptimized({int? unit}) async {
    try {
      _localLessons = await LocalService.getLocalLessons(unit: unit);
      
      // تحديث كاش الذاكرة
      if (unit != null) {
        _unitLessonsCache[unit] = List.from(_localLessons);
      }
      
      // تحديث كاش الدروس الفردية
      for (final lesson in _localLessons) {
        _lessonCache[lesson.id] = lesson;
      }
      
      _lessons = List.from(_localLessons);
      await _loadLocalProgress();
      
      notifyListeners();
      
    } catch (e) {
      _localLessons = [];
      _lessons = [];
    }
  }

  Future<void> _loadFromCacheOptimized({int? unit}) async {
    try {
      final cachedLessons = await CacheService.getCachedLessons(unit: unit);
      final cacheAge = await CacheService.getCacheAge();
      
      if (cachedLessons.isNotEmpty && cacheAge != null && 
          DateTime.now().difference(cacheAge).inMinutes < 20) {
        
        _mergeLessonsOptimized(cachedLessons);
        _lastCacheUpdate = cacheAge;
        
        notifyListeners();
      }
    } catch (e) {
      // تجاهل أخطاء الكاش
    }
  }

  void _mergeLessonsOptimized(List<LessonModel> newLessons) {
    final existingIds = _lessons.map((l) => l.id).toSet();
    final lessonsToAdd = newLessons.where((l) => !existingIds.contains(l.id));
    
    _lessons.addAll(lessonsToAdd);
    
    // تحديث كاش الذاكرة
    for (final lesson in lessonsToAdd) {
      _lessonCache[lesson.id] = lesson;
    }
    
    _sortLessons();
  }

  void _sortLessons() {
    _lessons.sort((a, b) {
      final unitComparison = a.unit.compareTo(b.unit);
      return unitComparison != 0 ? unitComparison : a.order.compareTo(b.order);
    });
  }

  Future<void> _loadFirebaseLessonsInBackground({int? unit}) async {
    try {
      // فحص الاتصال بشكل سريع
      _hasNetworkConnection = await _checkConnectionQuickly();
      
      if (!_hasNetworkConnection) return;
      
      final firebaseLessons = await FirebaseService.getLessons(unit: unit)
          .timeout(const Duration(seconds: 8));
      
      if (firebaseLessons.isNotEmpty) {
        _mergeLessonsOptimized(firebaseLessons);
        
        _saveToCacheAsync(firebaseLessons);
        
        notifyListeners();
      }
      
    } catch (e) {
      // تسجيل الخطأ بدون إيقاف التطبيق
      print('⚠️ فشل في تحميل دروس Firebase: $e');
    }
  }

  Future<bool> _checkConnectionQuickly() async {
    try {
      return await FirebaseService.checkConnection()
          .timeout(const Duration(seconds: 1), onTimeout: () => false);
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveToCacheAsync(List<LessonModel> lessons) async {
    try {
      await CacheService.cacheLessons(lessons);
      _lastCacheUpdate = DateTime.now();
    } catch (e) {
      print('⚠️ فشل في حفظ الكاش: $e');
    }
  }

  List<LessonModel> getAvailableLessons(List<String> completedQuizzes, int currentUnit) {
    if (_lessons.isEmpty) return [];
    
    // استخدام كاش الوحدة إذا متوفر
    List<LessonModel> unitLessons;
    if (_unitLessonsCache.containsKey(currentUnit)) {
      unitLessons = _unitLessonsCache[currentUnit]!;
    } else {
      unitLessons = _lessons.where((lesson) => lesson.unit == currentUnit).toList();
      unitLessons.sort((a, b) => a.order.compareTo(b.order));
      _unitLessonsCache[currentUnit] = unitLessons;
    }
    
    return unitLessons;
  }

  int _getUserCurrentUnit(Set<String> completedQuizzes) {
    if (_lessons.isEmpty) return 1;
    
    final availableUnits = _lessons.map((l) => l.unit).toSet().toList()..sort();
    
    for (int unit in availableUnits) {
      final unitLessons = _getUnitLessonsOptimized(unit);
      final completedInUnit = unitLessons.where((l) => completedQuizzes.contains(l.id)).length;
      
      if (completedInUnit < unitLessons.length) {
        return unit;
      }
    }
    
    return availableUnits.isNotEmpty ? availableUnits.last + 1 : 1;
  }

  List<LessonModel> _getUnitLessonsOptimized(int unit) {
    if (_unitLessonsCache.containsKey(unit)) {
      return _unitLessonsCache[unit]!;
    }
    
    final unitLessons = _lessons.where((l) => l.unit == unit).toList();
    unitLessons.sort((a, b) => a.order.compareTo(b.order));
    _unitLessonsCache[unit] = unitLessons;
    
    return unitLessons;
  }

  List<UnitInfo> getUnitsInfo(List<String> completedQuizzes) {
    if (_lessons.isEmpty) return [];
    
    final allCompletedQuizzes = <String>{};
    allCompletedQuizzes.addAll(completedQuizzes);
    allCompletedQuizzes.addAll(_localCompletedQuizzes);
    
    final availableUnits = _lessons.map((l) => l.unit).toSet().toList()..sort();
    final unitsInfo = <UnitInfo>[];
    
    for (int unit in availableUnits) {
      final unitLessons = _getUnitLessonsOptimized(unit);
      final completedCount = unitLessons.where((l) => allCompletedQuizzes.contains(l.id)).length;
      final isCompleted = completedCount == unitLessons.length;
      final isUnlocked = unit == 1 || (unit > 1 && unitsInfo.isNotEmpty && unitsInfo.last.isCompleted);
      
      final lessonsWithStatus = _getLessonsWithStatus(unitLessons, allCompletedQuizzes);
      
      unitsInfo.add(UnitInfo(
        unit: unit,
        title: _getUnitTitle(unit),
        totalLessons: unitLessons.length,
        completedLessons: completedCount,
        isCompleted: isCompleted,
        isUnlocked: isUnlocked,
        lessons: unitLessons,
        lessonsWithStatus: lessonsWithStatus,
      ));
    }
    
    return unitsInfo;
  }

  List<LessonWithStatus> _getLessonsWithStatus(List<LessonModel> lessons, Set<String> completedQuizzes) {
    return lessons.map((lesson) {
      LessonStatus status;
      if (completedQuizzes.contains(lesson.id)) {
        status = LessonStatus.completed;
      } else {
        final previousLesson = _getPreviousLesson(lesson);
        status = (previousLesson == null || completedQuizzes.contains(previousLesson.id))
            ? LessonStatus.open
            : LessonStatus.locked;
      }
      
      return LessonWithStatus(lesson: lesson, status: status);
    }).toList();
  }

  LessonModel? _getPreviousLesson(LessonModel lesson) {
    final unitLessons = _getUnitLessonsOptimized(lesson.unit);
    final currentIndex = unitLessons.indexWhere((l) => l.id == lesson.id);
    
    if (currentIndex > 0) {
      return unitLessons[currentIndex - 1];
    }
    
    if (lesson.unit > 1) {
      final previousUnitLessons = _getUnitLessonsOptimized(lesson.unit - 1);
      return previousUnitLessons.isNotEmpty ? previousUnitLessons.last : null;
    }
    
    return null;
  }

  String _getUnitTitle(int unit) {
    const unitTitles = {
      1: 'أساسيات Python',
      2: 'البرمجة المتقدمة',
      3: 'المشاريع العملية',
    };
    return unitTitles[unit] ?? 'الوحدة $unit';
  }

  Future<void> markQuizCompletedLocally(String lessonId) async {
    if (_localCompletedQuizzes.contains(lessonId)) return;
    
    try {
      _localCompletedQuizzes.add(lessonId);
      await _saveLocalProgress();
      
      _clearAffectedUnitCache(lessonId);
      
      notifyListeners();
      
    } catch (e) {
      _localCompletedQuizzes.remove(lessonId);
      print('❌ خطأ في تسجيل إكمال الاختبار محلياً: $e');
    }
  }

  void _clearAffectedUnitCache(String lessonId) {
    final lesson = _lessonCache[lessonId];
    if (lesson != null) {
      _unitLessonsCache.remove(lesson.unit);
    }
  }

  Future<void> saveQuizResult(String userId, String lessonId, QuizResultModel result) async {
    try {
      await FirebaseService.saveQuizResult(userId, lessonId, result);
      
      if (result.isPassed) {
        await markQuizCompletedLocally(lessonId);
        _syncQuizCompletionWithFirebase(userId, lessonId);
        await _updateDecayTracker(userId, lessonId);
      }
    } catch (e) {
      print('❌ خطأ في حفظ نتيجة الاختبار: $e');
    }
  }

  Future<void> saveEnhancedQuizResult(String userId, String lessonId, EnhancedQuizResult result) async {
    try {
      await FirebaseService.saveEnhancedQuizResult(userId, lessonId, result);
      
      if (QuizEngine.isPassing(result.percentage)) {
        await markQuizCompletedLocally(lessonId);
        _syncQuizCompletionWithFirebase(userId, lessonId);
        await _updateDecayTracker(userId, lessonId);
      }
      
      // حفظ الإحصائيات المحلية
      await _saveQuizStatistics(lessonId, result);
      
    } catch (e) {
      print('❌ خطأ في حفظ نتيجة الاختبار المحسنة: $e');
    }
  }

  Future<void> loadLesson(String lessonId, String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // فحص كاش الذاكرة أولاً
      if (_lessonCache.containsKey(lessonId)) {
        _currentLesson = _lessonCache[lessonId];
        notifyListeners();
        _setLoading(false);
        return;
      }
      
      // البحث في الدروس المحلية
      _currentLesson = await LocalService.getLocalLesson(lessonId);
      
      if (_currentLesson != null) {
        _lessonCache[lessonId] = _currentLesson!;
      } else {
        // البحث في Firebase
        _currentLesson = await FirebaseService.getLesson(lessonId);
        if (_currentLesson != null) {
          _lessonCache[lessonId] = _currentLesson!;
        }
      }
      
      notifyListeners();
    } catch (e) {
      _setError('فشل في تحميل الدرس: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveLocalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final futures = [
        prefs.setStringList('local_completed_quizzes', _localCompletedQuizzes.toList()),
        _saveDecayTrackers(),
        _saveStatisticsToLocal(),
      ];
      await Future.wait(futures);
    } catch (e) {
      print('❌ خطأ في حفظ التقدم المحلي: $e');
    }
  }

  Future<void> _loadLocalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedQuizzes = prefs.getStringList('local_completed_quizzes') ?? [];
      _localCompletedQuizzes = completedQuizzes.toSet();
      
      await _loadDecayTrackers();
      await _loadStatisticsFromLocal();
    } catch (e) {
      print('❌ خطأ في تحميل التقدم المحلي: $e');
      _localCompletedQuizzes = {};
      _decayTrackers = {};
      _quizHistory = {};
      _performanceStats = {};
    }
  }

  Future<void> _syncQuizCompletionWithFirebase(String userId, String lessonId) async {
    if (!_hasNetworkConnection) return;
    
    try {
      await FirebaseService.updateUserData(userId, {
        'completedLessons': FieldValue.arrayUnion([lessonId]),
      }).timeout(const Duration(seconds: 5));
      
      _localCompletedQuizzes.remove(lessonId);
      await _saveLocalProgress();
      
    } catch (e) {
      print('⚠️ فشل في مزامنة إكمال الاختبار مع Firebase: $e');
    }
  }

  Future<void> _updateDecayTracker(String userId, String lessonId) async {
    try {
      final existingTracker = _decayTrackers[lessonId];
      await updateDecayTracker(userId, lessonId, existingTracker);
    } catch (e) {
      print('❌ خطأ في تحديث decay tracker: $e');
    }
  }

  Future<void> updateDecayTracker(String userId, String lessonId, DecayTrackerModel? existingTracker) async {
    try {
      final now = DateTime.now();
      
      DecayTrackerModel newTracker;
      
      if (existingTracker == null) {
        newTracker = DecayTrackerModel(
          lessonId: lessonId,
          firstCompletionDate: now,
          lastRetakeDate: now,
          retakeCount: 0, // المرة الأولى - لا اضمحلال
        );
      } else {
        newTracker = existingTracker.withDailyReset().withNewRetake();
      }
      
      // حفظ في الكاش المحلي
      _decayTrackers[lessonId] = newTracker;
      await _saveDecayTrackers();
      
      // محاولة حفظ في Firebase
      if (_hasNetworkConnection) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('decayTrackers')
              .doc(lessonId)
              .set(newTracker.toMap())
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          print('⚠️ فشل في حفظ decay tracker في Firebase: $e');
        }
      }
      
    } catch (e) {
      print('❌ خطأ في تحديث decay tracker: $e');
    }
  }

  Future<DecayTrackerModel?> getDecayTracker(String userId, String lessonId) async {
    try {
      // البحث في الكاش المحلي أولاً
      if (_decayTrackers.containsKey(lessonId)) {
        return _decayTrackers[lessonId];
      }
      
      // محاولة جلب من Firebase إذا كان متاحاً
      if (_hasNetworkConnection) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('decayTrackers')
              .doc(lessonId)
              .get()
              .timeout(const Duration(seconds: 3));
          
          if (doc.exists) {
            final tracker = DecayTrackerModel.fromMap(doc.data()!);
            _decayTrackers[lessonId] = tracker;
            return tracker;
          }
        } catch (e) {
          print('⚠️ فشل في جلب decay tracker من Firebase: $e');
        }
      }
      
      // إرجاع null إذا لم يوجد tracker (المرة الأولى)
      return null;
    } catch (e) {
      print('❌ خطأ في جلب decay tracker: $e');
      return null;
    }
  }

  DecayTrackerModel? getDecayTrackerLocal(String lessonId) => _decayTrackers[lessonId];

  Future<void> _saveDecayTrackers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackersJson = _decayTrackers.map((key, value) => MapEntry(key, value.toMap()));
      await prefs.setString('decay_trackers', json.encode(trackersJson));
    } catch (e) {
      print('❌ خطأ في حفظ تتبع الاضمحلال: $e');
    }
  }

  Future<void> _loadDecayTrackers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackersString = prefs.getString('decay_trackers');
      
      if (trackersString != null) {
        final trackersJson = json.decode(trackersString) as Map<String, dynamic>;
        _decayTrackers = trackersJson.map(
          (key, value) => MapEntry(key, DecayTrackerModel.fromMap(value)),
        );
      }
    } catch (e) {
      print('❌ خطأ في تحميل تتبع الاضمحلال: $e');
      _decayTrackers = {};
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

  void clearCache() {
    _lessonCache.clear();
    _unitLessonsCache.clear();
    _lastCacheUpdate = null;
    _quizHistory.clear();
    _performanceStats.clear();
  }

  Future<void> _saveQuizStatistics(String lessonId, EnhancedQuizResult result) async {
    try {
      // إضافة النتيجة لتاريخ الاختبارات
      _quizHistory.putIfAbsent(lessonId, () => []);
      _quizHistory[lessonId]!.add(result);
      
      // الاحتفاظ بآخر 10 نتائج فقط
      if (_quizHistory[lessonId]!.length > 10) {
        _quizHistory[lessonId]!.removeAt(0);
      }
      
      // تحديث إحصائيات الأداء
      await _updatePerformanceStats(result.userId);
      
      // حفظ البيانات محلياً
      await _saveStatisticsToLocal();
      
    } catch (e) {
      print('❌ خطأ في حفظ إحصائيات الاختبار: $e');
    }
  }

  Future<void> _updatePerformanceStats(String userId) async {
    try {
      final allResults = _quizHistory.values.expand((results) => results).toList();
      final userResults = allResults.where((r) => r.userId == userId).toList();
      
      if (userResults.isEmpty) return;
      
      final analysis = QuizEngine.analyzePerformance(userResults);
      
      _performanceStats[userId] = UserPerformanceStats(
        userId: userId,
        totalQuizzes: analysis['totalQuizzes'] as int,
        averageScore: analysis['averageScore'] as double,
        strongAreas: (analysis['strongAreas'] as List).cast<QuestionType>(),
        weakAreas: (analysis['weakAreas'] as List).cast<QuestionType>(),
        improvementTrend: analysis['improvement'] as double,
        currentStreak: analysis['streakCount'] as int,
        lastUpdated: DateTime.now(),
      );
      
    } catch (e) {
      print('❌ خطأ في تحديث إحصائيات الأداء: $e');
    }
  }

  Future<void> _saveStatisticsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ تاريخ الاختبارات
      final historyJson = _quizHistory.map((key, value) => 
        MapEntry(key, value.map((result) => result.toJson()).toList()));
      await prefs.setString('quiz_history', json.encode(historyJson));
      
      // حفظ إحصائيات الأداء
      final statsJson = _performanceStats.map((key, value) => 
        MapEntry(key, value.toMap()));
      await prefs.setString('performance_stats', json.encode(statsJson));
      
    } catch (e) {
      print('❌ خطأ في حفظ الإحصائيات محلياً: $e');
    }
  }

  Future<void> _loadStatisticsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل تاريخ الاختبارات
      final historyString = prefs.getString('quiz_history');
      if (historyString != null) {
        final historyJson = json.decode(historyString) as Map<String, dynamic>;
        _quizHistory = historyJson.map((key, value) => MapEntry(
          key, 
          (value as List).map((item) => EnhancedQuizResult.fromJson(item)).toList()
        ));
      }
      
      // تحميل إحصائيات الأداء
      final statsString = prefs.getString('performance_stats');
      if (statsString != null) {
        final statsJson = json.decode(statsString) as Map<String, dynamic>;
        _performanceStats = statsJson.map((key, value) => MapEntry(
          key, 
          UserPerformanceStats.fromMap(value)
        ));
      }
      
    } catch (e) {
      print('❌ خطأ في تحميل الإحصائيات محلياً: $e');
      _quizHistory = {};
      _performanceStats = {};
    }
  }

  List<EnhancedQuizResult> getQuizHistory(String lessonId) {
    return _quizHistory[lessonId] ?? [];
  }

  UserPerformanceStats? getUserPerformanceStats(String userId) {
    return _performanceStats[userId];
  }

  Map<QuestionType, double> getQuestionTypePerformance(String userId) {
    final userResults = _quizHistory.values
        .expand((results) => results)
        .where((r) => r.userId == userId)
        .toList();
    
    if (userResults.isEmpty) return {};
    
    final typeStats = <QuestionType, List<bool>>{};
    
    for (final result in userResults) {
      for (final entry in result.questionResults.entries) {
        final questionData = entry.value as Map<String, dynamic>;
        final typeString = questionData['type'] as String;
        final isCorrect = questionData['isCorrect'] as bool;
        final type = QuestionTypeExtension.fromString(typeString);
        
        typeStats.putIfAbsent(type, () => []);
        typeStats[type]!.add(isCorrect);
      }
    }
    
    return typeStats.map((type, results) {
      final correctCount = results.where((correct) => correct).length;
      return MapEntry(type, correctCount / results.length * 100);
    });
  }

  List<DailyProgress> getDailyProgress(String userId, {int days = 7}) {
    final userResults = _quizHistory.values
        .expand((results) => results)
        .where((r) => r.userId == userId)
        .toList();
    
    final now = DateTime.now();
    final dailyProgress = <DailyProgress>[];
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayResults = userResults.where((r) => 
        r.completedAt.isAfter(dayStart) && r.completedAt.isBefore(dayEnd)
      ).toList();
      
      final totalQuizzes = dayResults.length;
      final passedQuizzes = dayResults.where((r) => QuizEngine.isPassing(r.percentage)).length;
      final averageScore = totalQuizzes > 0 
          ? dayResults.map((r) => r.percentage).reduce((a, b) => a + b) / totalQuizzes
          : 0.0;
      
      dailyProgress.add(DailyProgress(
        date: dayStart,
        totalQuizzes: totalQuizzes,
        passedQuizzes: passedQuizzes,
        averageScore: averageScore,
      ));
    }
    
    return dailyProgress;
  }

  StudyStreak getStudyStreak(String userId) {
    final userResults = _quizHistory.values
        .expand((results) => results)
        .where((r) => r.userId == userId)
        .toList();
    
    if (userResults.isEmpty) {
      return StudyStreak(currentStreak: 0, longestStreak: 0, lastStudyDate: null);
    }
    
    // ترتيب النتائج حسب التاريخ
    userResults.sort((a, b) => a.completedAt.compareTo(b.completedAt));
    
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;
    
    for (final result in userResults.reversed) {
      final resultDate = DateTime(
        result.completedAt.year,
        result.completedAt.month,
        result.completedAt.day,
      );
      
      if (lastDate == null) {
        tempStreak = 1;
        lastDate = resultDate;
      } else {
        final daysDifference = lastDate.difference(resultDate).inDays;
        
        if (daysDifference == 1) {
          tempStreak++;
        } else if (daysDifference > 1) {
          if (currentStreak == 0) currentStreak = tempStreak;
          longestStreak = math.max(longestStreak, tempStreak);
          tempStreak = 1;
        }
        
        lastDate = resultDate;
      }
    }
    
    if (currentStreak == 0) currentStreak = tempStreak;
    longestStreak = math.max(longestStreak, tempStreak);
    
    // التحقق من استمرارية السلسلة
    final today = DateTime.now();
    final lastStudyDate = userResults.last.completedAt;
    final daysSinceLastStudy = today.difference(DateTime(
      lastStudyDate.year,
      lastStudyDate.month,
      lastStudyDate.day,
    )).inDays;
    
    if (daysSinceLastStudy > 1) {
      currentStreak = 0;
    }
    
    return StudyStreak(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastStudyDate: lastStudyDate,
    );
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
  final List<LessonWithStatus> lessonsWithStatus;

  UnitInfo({
    required this.unit,
    required this.title,
    required this.totalLessons,
    required this.completedLessons,
    required this.isCompleted,
    required this.isUnlocked,
    required this.lessons,
    required this.lessonsWithStatus,
  });

  double get progress => totalLessons > 0 ? completedLessons / totalLessons : 0.0;
}

/// حالة الدرس
enum LessonStatus {
  open,      // مفتوح
  completed, // مكتمل
  locked,    // مغلق
}

/// درس مع حالته
class LessonWithStatus {
  final LessonModel lesson;
  final LessonStatus status;

  LessonWithStatus({
    required this.lesson,
    required this.status,
  });
}

class UserPerformanceStats {
  final String userId;
  final int totalQuizzes;
  final double averageScore;
  final List<QuestionType> strongAreas;
  final List<QuestionType> weakAreas;
  final double improvementTrend;
  final int currentStreak;
  final DateTime lastUpdated;

  UserPerformanceStats({
    required this.userId,
    required this.totalQuizzes,
    required this.averageScore,
    required this.strongAreas,
    required this.weakAreas,
    required this.improvementTrend,
    required this.currentStreak,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalQuizzes': totalQuizzes,
      'averageScore': averageScore,
      'strongAreas': strongAreas.map((type) => type.toString()).toList(),
      'weakAreas': weakAreas.map((type) => type.toString()).toList(),
      'improvementTrend': improvementTrend,
      'currentStreak': currentStreak,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserPerformanceStats.fromMap(Map<String, dynamic> map) {
    return UserPerformanceStats(
      userId: map['userId'] ?? '',
      totalQuizzes: map['totalQuizzes'] ?? 0,
      averageScore: (map['averageScore'] ?? 0.0).toDouble(),
      strongAreas: (map['strongAreas'] as List<dynamic>?)
          ?.map((type) => _parseQuestionType(type.toString()))
          .toList() ?? [],
      weakAreas: (map['weakAreas'] as List<dynamic>?)
          ?.map((type) => _parseQuestionType(type.toString()))
          .toList() ?? [],
      improvementTrend: (map['improvementTrend'] ?? 0.0).toDouble(),
      currentStreak: map['currentStreak'] ?? 0,
      lastUpdated: DateTime.parse(map['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  static QuestionType _parseQuestionType(String typeString) {
    return QuestionTypeExtension.fromString(typeString);
  }
}

class DailyProgress {
  final DateTime date;
  final int totalQuizzes;
  final int passedQuizzes;
  final double averageScore;

  DailyProgress({
    required this.date,
    required this.totalQuizzes,
    required this.passedQuizzes,
    required this.averageScore,
  });

  double get successRate => totalQuizzes > 0 ? passedQuizzes / totalQuizzes : 0.0;
}

class StudyStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;

  StudyStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastStudyDate,
  });

  bool get isActive {
    if (lastStudyDate == null) return false;
    final today = DateTime.now();
    final daysSinceLastStudy = today.difference(DateTime(
      lastStudyDate!.year,
      lastStudyDate!.month,
      lastStudyDate!.day,
    )).inDays;
    return daysSinceLastStudy <= 1;
  }
}
