import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../services/local_service.dart';
import '../services/cache_service.dart';
import '../services/reward_service.dart';
import '../models/lesson_model.dart';
import '../models/quiz_result_model.dart';

class LessonProvider with ChangeNotifier {
  final Map<int, List<LessonModel>> _unitLessons = {}; // دروس مقسمة حسب الوحدة
  final Map<String, LessonModel> _loadedLessons = {}; // دروس محملة في الذاكرة
  final Set<int> _loadedUnits = {}; // الوحدات المحملة
  final Set<int> _loadingUnits = {}; // الوحدات قيد التحميل
  final Map<String, DateTime> _lessonAccessTime = {}; // وقت آخر وصول للدرس
  
  List<LessonModel> _localLessons = [];
  LessonModel? _currentLesson;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasNetworkConnection = true;
  DateTime? _lastCacheUpdate;
  
  // تتبع محلي للاختبارات المكتملة فقط (بدون XP/Gems منفصلة)
  Set<String> _localCompletedQuizzes = {};

  // إعدادات إدارة الذاكرة
  static const int _maxLoadedLessons = 20; // الحد الأقصى للدروس في الذاكرة
  static const int _maxLoadedUnits = 3; // الحد الأقصى للوحدات المحملة
  static const Duration _lessonCacheTimeout = Duration(minutes: 30); // مهلة انتهاء الدرس في الذاكرة

  List<LessonModel> get lessons => _getAllLoadedLessons();
  List<LessonModel> get localLessons => _localLessons;
  LessonModel? get currentLesson => _currentLesson;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNetworkConnection => _hasNetworkConnection;
  
  Set<int> get loadedUnits => Set.from(_loadedUnits);
  Set<int> get loadingUnits => Set.from(_loadingUnits);
  int get totalLoadedLessons => _loadedLessons.length;

  /// الحصول على جميع الدروس المحملة مع إزالة التكرار
  List<LessonModel> _getAllLoadedLessons() {
    final uniqueLessons = <String, LessonModel>{};
    
    // إضافة الدروس المحلية
    for (var lesson in _localLessons) {
      uniqueLessons[lesson.id] = lesson;
    }
    
    // إضافة الدروس المحملة (تحل محل المحلية إذا كانت أحدث)
    for (var lesson in _loadedLessons.values) {
      uniqueLessons[lesson.id] = lesson;
    }
    
    final result = uniqueLessons.values.toList();
    result.sort((a, b) {
      if (a.unit != b.unit) return a.unit.compareTo(b.unit);
      return a.order.compareTo(b.order);
    });
    
    return result;
  }

  /// تحميل فوري للدروس مع أولوية للمحتوى المحلي والتحميل التدريجي
  Future<void> loadLessons({int? unit, bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();
      
      await clearDuplicateData();
      
      // المرحلة 1: تحميل الدروس المحلية فوراً (أولوية قصوى)
      await _loadLocalLessonsInstantly(unit: unit);
      
      // المرحلة 2: تحميل الوحدة المطلوبة أو الوحدة الحالية
      final targetUnit = unit ?? _determineCurrentUnit();
      await _loadUnitProgressively(targetUnit, forceRefresh: forceRefresh);
      
      // المرحلة 3: تحميل مسبق للوحدة التالية في الخلفية
      _preloadNextUnit(targetUnit);
      
      // المرحلة 4: تنظيف الذاكرة
      await _cleanupMemory();
      
    } catch (e) {
      _setError('فشل في تحميل الدروس');
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل وحدة معينة بشكل تدريجي
  Future<void> _loadUnitProgressively(int unit, {bool forceRefresh = false}) async {
    if (_loadingUnits.contains(unit)) return; // تجنب التحميل المتكرر
    
    try {
      _loadingUnits.add(unit);
      
      // التحقق من وجود الوحدة في الكاش
      if (!forceRefresh && _loadedUnits.contains(unit)) {
        print('✅ الوحدة $unit محملة مسبقاً');
        return;
      }
      
      // تحميل من الكاش أولاً
      final cachedLessons = await CacheService.getCachedLessons(
        unit: unit, 
        prioritizeUnit: true
      );
      
      if (cachedLessons.isNotEmpty && await CacheService.isCacheValid()) {
        _unitLessons[unit] = cachedLessons;
        _loadedUnits.add(unit);
        
        // إضافة للدروس المحملة
        for (var lesson in cachedLessons) {
          _loadedLessons[lesson.id] = lesson;
          _lessonAccessTime[lesson.id] = DateTime.now();
        }
        
        notifyListeners();
        print('✅ تم تحميل الوحدة $unit من الكاش (${cachedLessons.length} دروس)');
      }
      
      // تحميل من Firebase في الخلفية
      _loadUnitFromFirebaseInBackground(unit);
      
    } catch (e) {
      print('❌ خطأ في تحميل الوحدة $unit: $e');
    } finally {
      _loadingUnits.remove(unit);
    }
  }

  /// تحميل وحدة من Firebase في الخلفية
  Future<void> _loadUnitFromFirebaseInBackground(int unit) async {
    try {
      _hasNetworkConnection = await FirebaseService.checkConnection()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      
      if (!_hasNetworkConnection) return;
      
      final firebaseLessons = await FirebaseService.getLessons(unit: unit)
          .timeout(const Duration(seconds: 10), onTimeout: () => <LessonModel>[]);
      
      if (firebaseLessons.isNotEmpty) {
        _unitLessons[unit] = firebaseLessons;
        _loadedUnits.add(unit);
        
        // تحديث الدروس المحملة
        for (var lesson in firebaseLessons) {
          _loadedLessons[lesson.id] = lesson;
          _lessonAccessTime[lesson.id] = DateTime.now();
        }
        
        // حفظ في الكاش
        await CacheService.updateCachePartially(firebaseLessons);
        
        notifyListeners();
        print('✅ تم تحميل الوحدة $unit من Firebase (${firebaseLessons.length} دروس)');
      }
      
    } catch (e) {
      print('❌ خطأ في تحميل الوحدة $unit من Firebase: $e');
    }
  }

  /// تحديد الوحدة الحالية للمستخدم
  int _determineCurrentUnit() {
    final allCompletedQuizzes = <String>{};
    allCompletedQuizzes.addAll(_localCompletedQuizzes);
    
    // البحث في الوحدات المحملة
    final availableUnits = _unitLessons.keys.toList()..sort();
    
    for (int unit in availableUnits) {
      final unitLessons = _unitLessons[unit] ?? [];
      final completedInUnit = unitLessons.where((l) => allCompletedQuizzes.contains(l.id)).length;
      
      if (completedInUnit < unitLessons.length) {
        return unit;
      }
    }
    
    return availableUnits.isNotEmpty ? availableUnits.last + 1 : 1;
  }

  /// تحميل مسبق للوحدة التالية
  void _preloadNextUnit(int currentUnit) {
    final nextUnit = currentUnit + 1;
    
    // تحميل في الخلفية بدون انتظار
    Future.delayed(const Duration(seconds: 2), () {
      if (!_loadedUnits.contains(nextUnit) && !_loadingUnits.contains(nextUnit)) {
        _loadUnitProgressively(nextUnit);
      }
    });
  }

  /// تنظيف الذاكرة من الدروس والوحدات غير المستخدمة
  Future<void> _cleanupMemory() async {
    try {
      final now = DateTime.now();
      
      // تنظيف الدروس القديمة
      final expiredLessons = <String>[];
      for (var entry in _lessonAccessTime.entries) {
        if (now.difference(entry.value) > _lessonCacheTimeout) {
          expiredLessons.add(entry.key);
        }
      }
      
      for (var lessonId in expiredLessons) {
        _loadedLessons.remove(lessonId);
        _lessonAccessTime.remove(lessonId);
      }
      
      // تنظيف الوحدات الزائدة
      if (_loadedUnits.length > _maxLoadedUnits) {
        final sortedUnits = _loadedUnits.toList()..sort();
        final unitsToRemove = sortedUnits.take(_loadedUnits.length - _maxLoadedUnits);
        
        for (var unit in unitsToRemove) {
          final unitLessons = _unitLessons[unit] ?? [];
          for (var lesson in unitLessons) {
            _loadedLessons.remove(lesson.id);
            _lessonAccessTime.remove(lesson.id);
          }
          _unitLessons.remove(unit);
          _loadedUnits.remove(unit);
        }
      }
      
      // تنظيف الدروس الزائدة
      if (_loadedLessons.length > _maxLoadedLessons) {
        final sortedLessons = _lessonAccessTime.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        
        final lessonsToRemove = sortedLessons
            .take(_loadedLessons.length - _maxLoadedLessons)
            .map((e) => e.key);
        
        for (var lessonId in lessonsToRemove) {
          _loadedLessons.remove(lessonId);
          _lessonAccessTime.remove(lessonId);
        }
      }
      
      if (expiredLessons.isNotEmpty || _loadedLessons.length > _maxLoadedLessons) {
        print('🧹 تم تنظيف الذاكرة: ${expiredLessons.length} دروس منتهية الصلاحية');
      }
      
    } catch (e) {
      print('❌ خطأ في تنظيف الذاكرة: $e');
    }
  }

  /// تحميل الدروس المحلية فوراً
  Future<void> _loadLocalLessonsInstantly({int? unit}) async {
    try {
      _localLessons = await LocalService.getLocalLessons(unit: unit);
      
      // إضافة للدروس المحملة
      for (var lesson in _localLessons) {
        _loadedLessons[lesson.id] = lesson;
        _lessonAccessTime[lesson.id] = DateTime.now();
        
        // تجميع حسب الوحدة
        _unitLessons.putIfAbsent(lesson.unit, () => []).add(lesson);
        _loadedUnits.add(lesson.unit);
      }
      
      // تحميل التقدم المحلي
      await _loadLocalProgress();
      
      // إشعار فوري لعرض الدروس
      notifyListeners();
      
    } catch (e) {
      _localLessons = [];
    }
  }

  /// الحصول على الدروس المتاحة بناءً على نظام الوحدات - مع التحميل التدريجي
  List<LessonModel> getAvailableLessons(List<String> completedQuizzes, int currentUnit) {
    // التأكد من تحميل الوحدة المطلوبة
    if (!_loadedUnits.contains(currentUnit)) {
      _loadUnitProgressively(currentUnit);
      return []; // إرجاع قائمة فارغة حتى يتم التحميل
    }
    
    final unitLessons = _unitLessons[currentUnit] ?? [];
    if (unitLessons.isEmpty) return [];
    
    // دمج الاختبارات المكتملة مع التقدم المحلي
    final allCompletedQuizzes = <String>{};
    allCompletedQuizzes.addAll(completedQuizzes);
    allCompletedQuizzes.addAll(_localCompletedQuizzes);
    
    // ترتيب الدروس حسب الترتيب
    unitLessons.sort((a, b) => a.order.compareTo(b.order));
    
    return unitLessons;
  }

  /// الحصول على معلومات الوحدات للعرض - مع دعم التحميل التدريجي
  List<UnitInfo> getUnitsInfo(List<String> completedQuizzes) {
    final allCompletedQuizzes = <String>{};
    allCompletedQuizzes.addAll(completedQuizzes);
    allCompletedQuizzes.addAll(_localCompletedQuizzes);
    
    final availableUnits = _unitLessons.keys.toList()..sort();
    final unitsInfo = <UnitInfo>[];
    
    for (int unit in availableUnits) {
      final unitLessons = _unitLessons[unit] ?? [];
      final completedCount = unitLessons.where((l) => allCompletedQuizzes.contains(l.id)).length;
      final isCompleted = completedCount == unitLessons.length;
      final isUnlocked = unit == 1 || (unit > 1 && unitsInfo.isNotEmpty && unitsInfo.last.isCompleted);
      final isLoaded = _loadedUnits.contains(unit);
      final isLoading = _loadingUnits.contains(unit);
      
      // تحديد حالة كل درس
      final lessonsWithStatus = unitLessons.map((lesson) {
        // تحديث وقت الوصول
        _lessonAccessTime[lesson.id] = DateTime.now();
        
        LessonStatus status;
        if (lesson.unit == 1 && lesson.order == 1) {
          status = LessonStatus.open;
        } else if (allCompletedQuizzes.contains(lesson.id)) {
          status = LessonStatus.completed;
        } else {
          final previousLesson = _getPreviousLesson(lesson);
          if (previousLesson == null || allCompletedQuizzes.contains(previousLesson.id)) {
            status = LessonStatus.open;
          } else {
            status = LessonStatus.locked;
          }
        }
        
        return LessonWithStatus(lesson: lesson, status: status);
      }).toList();
      
      unitsInfo.add(UnitInfo(
        unit: unit,
        title: _getUnitTitle(unit),
        totalLessons: unitLessons.length,
        completedLessons: completedCount,
        isCompleted: isCompleted,
        isUnlocked: isUnlocked,
        isLoaded: isLoaded, // إضافة حالة التحميل
        isLoading: isLoading, // إضافة حالة التحميل الجاري
        lessons: unitLessons,
        lessonsWithStatus: lessonsWithStatus,
      ));
    }
    
    return unitsInfo;
  }

  /// تحميل درس معين مع أولوية للمحتوى المحلي والتحميل الذكي
  Future<void> loadLesson(String lessonId, String userId) async {
    try {
      print('🚀 بدء تحميل الدرس: $lessonId للمستخدم: $userId');
      _setLoading(true);
      _clearError();
      
      // البحث في الدروس المحملة أولاً
      if (_loadedLessons.containsKey(lessonId)) {
        _currentLesson = _loadedLessons[lessonId];
        _lessonAccessTime[lessonId] = DateTime.now(); // تحديث وقت الوصول
        print('✅ تم العثور على الدرس في الذاكرة: ${_currentLesson!.title}');
        notifyListeners();
        return;
      }
      
      // البحث في الدروس المحلية
      print('🔍 البحث في الدروس المحلية...');
      _currentLesson = await LocalService.getLocalLesson(lessonId);
      
      if (_currentLesson != null) {
        print('✅ تم العثور على الدرس محلياً: ${_currentLesson!.title}');
        
        // إضافة للذاكرة
        _loadedLessons[lessonId] = _currentLesson!;
        _lessonAccessTime[lessonId] = DateTime.now();
      } else {
        print('⚠️ لم يتم العثور على الدرس محلياً، البحث في Firebase...');
        
        // البحث في Firebase
        _currentLesson = await FirebaseService.getLesson(lessonId);
        
        if (_currentLesson != null) {
          print('✅ تم العثور على الدرس في Firebase: ${_currentLesson!.title}');
          
          // إضافة للذاكرة والكاش
          _loadedLessons[lessonId] = _currentLesson!;
          _lessonAccessTime[lessonId] = DateTime.now();
          await CacheService.cacheLesson(_currentLesson!);
        } else {
          print('❌ لم يتم العثور على الدرس في أي مكان');
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في تحميل الدرس: $e');
      _setError('فشل في تحميل الدرس: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل وحدة معينة عند الطلب
  Future<void> loadUnit(int unit, {bool forceRefresh = false}) async {
    await _loadUnitProgressively(unit, forceRefresh: forceRefresh);
  }

  /// إلغاء تحميل وحدة معينة لتوفير الذاكرة
  Future<void> unloadUnit(int unit) async {
    try {
      final unitLessons = _unitLessons[unit] ?? [];
      
      // إزالة دروس الوحدة من الذاكرة
      for (var lesson in unitLessons) {
        _loadedLessons.remove(lesson.id);
        _lessonAccessTime.remove(lesson.id);
      }
      
      _unitLessons.remove(unit);
      _loadedUnits.remove(unit);
      
      notifyListeners();
      print('🗑️ تم إلغاء تحميل الوحدة $unit من الذاكرة');
    } catch (e) {
      print('❌ خطأ في إلغاء تحميل الوحدة $unit: $e');
    }
  }

  /// الحصول على إحصائيات الذاكرة
  MemoryStats getMemoryStats() {
    return MemoryStats(
      loadedLessons: _loadedLessons.length,
      loadedUnits: _loadedUnits.length,
      loadingUnits: _loadingUnits.length,
      localLessons: _localLessons.length,
      maxLoadedLessons: _maxLoadedLessons,
      maxLoadedUnits: _maxLoadedUnits,
    );
  }

  /// الحصول على الدرس السابق
  LessonModel? _getPreviousLesson(LessonModel lesson) {
    final unitLessons = _unitLessons[lesson.unit] ?? [];
    unitLessons.sort((a, b) => a.order.compareTo(b.order));
    
    final currentIndex = unitLessons.indexWhere((l) => l.id == lesson.id);
    if (currentIndex > 0) {
      return unitLessons[currentIndex - 1];
    }
    
    // إذا كان أول درس في الوحدة، فحص آخر درس في الوحدة السابقة
    if (lesson.unit > 1) {
      final previousUnitLessons = _unitLessons[lesson.unit - 1] ?? [];
      if (previousUnitLessons.isNotEmpty) {
        previousUnitLessons.sort((a, b) => a.order.compareTo(b.order));
        return previousUnitLessons.last;
      }
    }
    
    return null;
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

  /// تسجيل إكمال الاختبار محلياً (بدون حساب مكافآت)
  Future<void> markQuizCompletedLocally(String lessonId) async {
    try {
      _localCompletedQuizzes.add(lessonId);
      await _saveLocalProgress();
      notifyListeners();
      
      print('✅ تم تسجيل إكمال الاختبار محلياً: $lessonId');
    } catch (e) {
      print('❌ خطأ في تسجيل إكمال الاختبار محلياً: $e');
    }
  }

  /// حفظ نتيجة الاختبار في Firebase
  Future<void> saveQuizResult(String userId, String lessonId, QuizResultModel result) async {
    try {
      await FirebaseService.saveQuizResult(userId, lessonId, result);
      
      // تسجيل الإكمال محلياً
      await markQuizCompletedLocally(lessonId);
      
      // مزامنة مع Firebase في الخلفية
      _syncQuizCompletionWithFirebase(userId, lessonId);
    } catch (e) {
      print('❌ خطأ في حفظ نتيجة الاختبار: $e');
    }
  }

  /// حفظ التقدم المحلي (الاختبارات المكتملة فقط)
  Future<void> _saveLocalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_completed_quizzes', _localCompletedQuizzes.toList());
    } catch (e) {
      print('❌ خطأ في حفظ التقدم المحلي: $e');
    }
  }

  /// تحميل التقدم المحلي (الاختبارات المكتملة فقط)
  Future<void> _loadLocalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedQuizzes = prefs.getStringList('local_completed_quizzes') ?? [];
      _localCompletedQuizzes = completedQuizzes.toSet();
    } catch (e) {
      print('❌ خطأ في تحميل التقدم المحلي: $e');
      _localCompletedQuizzes = {};
    }
  }

  /// مزامنة إكمال الاختبار مع Firebase (بدون حساب مكافآت)
  Future<void> _syncQuizCompletionWithFirebase(String userId, String lessonId) async {
    if (!_hasNetworkConnection) return;
    
    try {
      // تحديث قائمة الدروس المكتملة في Firebase
      await FirebaseService.updateUserData(userId, {
        'completedLessons': FieldValue.arrayUnion([lessonId]),
      }).timeout(const Duration(seconds: 10));
      
      // إزالة من القائمة المحلية بعد المزامنة الناجحة
      _localCompletedQuizzes.remove(lessonId);
      await _saveLocalProgress();
      
      print('🔄 تم مزامنة إكمال الاختبار مع Firebase: $lessonId');
    } catch (e) {
      print('⚠️ فشل في مزامنة إكمال الاختبار مع Firebase: $e');
    }
  }

  /// الحصول على الدرس التالي المتاح للفتح
  LessonModel? getNextAvailableLesson(List<String> completedQuizzes) {
    final allCompletedQuizzes = <String>{};
    allCompletedQuizzes.addAll(completedQuizzes);
    allCompletedQuizzes.addAll(_localCompletedQuizzes);
    
    final availableUnits = _unitLessons.keys.toList()..sort();
    
    for (int unit in availableUnits) {
      final unitLessons = _unitLessons[unit] ?? [];
      unitLessons.sort((a, b) => a.order.compareTo(b.order));
      
      for (var lesson in unitLessons) {
        // إذا لم يكن الدرس مكتملاً وكان متاحاً للفتح
        if (!allCompletedQuizzes.contains(lesson.id)) {
          final previousLesson = _getPreviousLesson(lesson);
          if (previousLesson == null || allCompletedQuizzes.contains(previousLesson.id)) {
            return lesson;
          }
        }
      }
    }
    
    return null;
  }

  /// فتح الدرس التالي بعد إكمال درس معين
  Future<LessonModel?> unlockNextLesson(String completedLessonId, List<String> completedQuizzes) async {
    try {
      final completedLesson = _loadedLessons[completedLessonId];
      if (completedLesson == null) return null;
      
      // البحث عن الدرس التالي في نفس الوحدة
      final unitLessons = _unitLessons[completedLesson.unit] ?? [];
      unitLessons.sort((a, b) => a.order.compareTo(b.order));
      
      final currentIndex = unitLessons.indexWhere((l) => l.id == completedLessonId);
      
      // إذا كان هناك درس تالي في نفس الوحدة
      if (currentIndex >= 0 && currentIndex < unitLessons.length - 1) {
        final nextLesson = unitLessons[currentIndex + 1];
        
        // تحديث وقت الوصول للدرس التالي
        _lessonAccessTime[nextLesson.id] = DateTime.now();
        
        print('✅ تم فتح الدرس التالي: ${nextLesson.title}');
        notifyListeners();
        return nextLesson;
      }
      
      // إذا انتهت الوحدة، فتح أول درس في الوحدة التالية
      final nextUnit = completedLesson.unit + 1;
      
      // التأكد من تحميل الوحدة التالية
      if (!_loadedUnits.contains(nextUnit)) {
        await _loadUnitProgressively(nextUnit);
      }
      
      final nextUnitLessons = _unitLessons[nextUnit] ?? [];
      if (nextUnitLessons.isNotEmpty) {
        nextUnitLessons.sort((a, b) => a.order.compareTo(b.order));
        final firstLessonInNextUnit = nextUnitLessons.first;
        
        // تحديث وقت الوصول
        _lessonAccessTime[firstLessonInNextUnit.id] = DateTime.now();
        
        print('✅ تم فتح أول درس في الوحدة التالية: ${firstLessonInNextUnit.title}');
        notifyListeners();
        return firstLessonInNextUnit;
      }
      
      return null;
    } catch (e) {
      print('❌ خطأ في فتح الدرس التالي: $e');
      return null;
    }
  }

  /// تحديث حالة الدرس فوراً بعد إكمال الاختبار
  Future<void> updateLessonStateAfterCompletion(String lessonId, String userId, bool passed) async {
    try {
      if (passed) {
        // تسجيل الإكمال محلياً
        await markQuizCompletedLocally(lessonId);
        
        // تحديث حالة الدرس في الذاكرة
        if (_loadedLessons.containsKey(lessonId)) {
          final lesson = _loadedLessons[lessonId]!;
          // يمكن إضافة خاصية completed للدرس إذا لزم الأمر
        }
        
        // إشعار فوري للواجهة
        notifyListeners();
        
        print('✅ تم تحديث حالة الدرس بعد النجاح: $lessonId');
      }
    } catch (e) {
      print('❌ خطأ في تحديث حالة الدرس: $e');
    }
  }

  /// التحقق من إمكانية الوصول للدرس
  bool canAccessLesson(String lessonId, List<String> completedQuizzes) {
    final lesson = _loadedLessons[lessonId];
    if (lesson == null) return false;
    
    // الدرس الأول في الوحدة الأولى متاح دائماً
    if (lesson.unit == 1 && lesson.order == 1) {
      return true;
    }
    
    final allCompletedQuizzes = <String>{};
    allCompletedQuizzes.addAll(completedQuizzes);
    allCompletedQuizzes.addAll(_localCompletedQuizzes);
    
    // التحقق من إكمال الدرس السابق
    final previousLesson = _getPreviousLesson(lesson);
    return previousLesson == null || allCompletedQuizzes.contains(previousLesson.id);
  }

  /// الحصول على إحصائيات التقدم للوحدة
  UnitProgressStats getUnitProgressStats(int unit, List<String> completedQuizzes) {
    final unitLessons = _unitLessons[unit] ?? [];
    if (unitLessons.isEmpty) {
      return UnitProgressStats(
        unit: unit,
        totalLessons: 0,
        completedLessons: 0,
        availableLessons: 0,
        lockedLessons: 0,
      );
    }
    
    final allCompletedQuizzes = <String>{};
    allCompletedQuizzes.addAll(completedQuizzes);
    allCompletedQuizzes.addAll(_localCompletedQuizzes);
    
    int completed = 0;
    int available = 0;
    int locked = 0;
    
    for (var lesson in unitLessons) {
      if (allCompletedQuizzes.contains(lesson.id)) {
        completed++;
      } else if (canAccessLesson(lesson.id, completedQuizzes)) {
        available++;
      } else {
        locked++;
      }
    }
    
    return UnitProgressStats(
      unit: unit,
      totalLessons: unitLessons.length,
      completedLessons: completed,
      availableLessons: available,
      lockedLessons: locked,
    );
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

  /// تنظيف البيانات المكررة والمتداخلة
  Future<void> clearDuplicateData() async {
    try {
      print('🧹 بدء تنظيف البيانات المكررة...');
      
      // تنظيف الدروس المكررة في الذاكرة
      final uniqueLessons = <String, LessonModel>{};
      for (var lesson in _loadedLessons.values) {
        uniqueLessons[lesson.id] = lesson;
      }
      _loadedLessons.clear();
      _loadedLessons.addAll(uniqueLessons);
      
      // تنظيف الوحدات المكررة
      final cleanedUnits = <int, List<LessonModel>>{};
      for (var entry in _unitLessons.entries) {
        final uniqueUnitLessons = <String, LessonModel>{};
        for (var lesson in entry.value) {
          uniqueUnitLessons[lesson.id] = lesson;
        }
        cleanedUnits[entry.key] = uniqueUnitLessons.values.toList();
      }
      _unitLessons.clear();
      _unitLessons.addAll(cleanedUnits);
      
      // تنظيف الدروس المحلية المكررة
      final uniqueLocalLessons = <String, LessonModel>{};
      for (var lesson in _localLessons) {
        uniqueLocalLessons[lesson.id] = lesson;
      }
      _localLessons = uniqueLocalLessons.values.toList();
      
      await _cleanupOldSharedPreferencesData();
      
      print('✅ تم تنظيف البيانات المكررة - الدروس المحملة: ${_loadedLessons.length}');
      
    } catch (e) {
      print('❌ خطأ في تنظيف البيانات المكررة: $e');
    }
  }

  /// تنظيف البيانات القديمة من SharedPreferences
  Future<void> _cleanupOldSharedPreferencesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int cleanedCount = 0;
      
      for (String key in keys) {
        // تنظيف البيانات المتعلقة بالمشاركة
        if (key.contains('share') || 
            key.contains('sharing') ||
            key.contains('shared')) {
          await prefs.remove(key);
          cleanedCount++;
          continue;
        }
        
        // تنظيف البيانات القديمة
        if (key.contains('_level_') ||
            key.startsWith('old_') ||
            key.contains('legacy_') ||
            key.contains('deprecated_') ||
            key.endsWith('_old') ||
            key.contains('backup_')) {
          await prefs.remove(key);
          cleanedCount++;
          continue;
        }
        
        // تنظيف البيانات المكررة
        if (key.contains('duplicate_') ||
            key.contains('_copy') ||
            key.contains('temp_')) {
          await prefs.remove(key);
          cleanedCount++;
          continue;
        }
      }
      
      if (cleanedCount > 0) {
        print('🧹 تم تنظيف $cleanedCount مفتاح من البيانات القديمة في SharedPreferences');
      }
      
    } catch (e) {
      print('❌ خطأ في تنظيف البيانات القديمة من SharedPreferences: $e');
    }
  }
}

/// معلومات الوحدة للعرض - مع دعم التحميل التدريجي
class UnitInfo {
  final int unit;
  final String title;
  final int totalLessons;
  final int completedLessons;
  final bool isCompleted;
  final bool isUnlocked;
  final bool isLoaded; // إضافة حالة التحميل
  final bool isLoading; // إضافة حالة التحميل الجاري
  final List<LessonModel> lessons;
  final List<LessonWithStatus> lessonsWithStatus;

  UnitInfo({
    required this.unit,
    required this.title,
    required this.totalLessons,
    required this.completedLessons,
    required this.isCompleted,
    required this.isUnlocked,
    required this.isLoaded, // إضافة المعامل الجديد
    required this.isLoading, // إضافة المعامل الجديد
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

/// إحصائيات الذاكرة
class MemoryStats {
  final int loadedLessons;
  final int loadedUnits;
  final int loadingUnits;
  final int localLessons;
  final int maxLoadedLessons;
  final int maxLoadedUnits;

  MemoryStats({
    required this.loadedLessons,
    required this.loadedUnits,
    required this.loadingUnits,
    required this.localLessons,
    required this.maxLoadedLessons,
    required this.maxLoadedUnits,
  });

  double get memoryUsagePercentage => 
      maxLoadedLessons > 0 ? (loadedLessons / maxLoadedLessons) * 100 : 0;

  bool get isMemoryFull => loadedLessons >= maxLoadedLessons;
  bool get isUnitsLimitReached => loadedUnits >= maxLoadedUnits;
}

/// إحصائيات التقدم للوحدة
class UnitProgressStats {
  final int unit;
  final int totalLessons;
  final int completedLessons;
  final int availableLessons;
  final int lockedLessons;

  UnitProgressStats({
    required this.unit,
    required this.totalLessons,
    required this.completedLessons,
    required this.availableLessons,
    required this.lockedLessons,
  });

  double get completionPercentage => 
      totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0;

  bool get isCompleted => completedLessons == totalLessons;
  bool get hasAvailableLessons => availableLessons > 0;
}
