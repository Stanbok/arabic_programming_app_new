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
  final Map<int, List<LessonModel>> _lessonsByUnit = {};
  final Map<int, bool> _unitLoadingStates = {};
  final Map<int, bool> _unitLoadedStates = {};
  final Set<int> _preloadingUnits = {};
  
  // إعدادات التحميل التدريجي
  static const int _lessonsPerBatch = 5;
  static const int _maxPreloadUnits = 2;
  
  List<LessonModel> _lessons = [];
  List<LessonModel> _localLessons = [];
  LessonModel? _currentLesson;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasNetworkConnection = true;
  DateTime? _lastCacheUpdate;
  
  // تتبع محلي للاختبارات المكتملة فقط (بدون XP/Gems منفصلة)
  Set<String> _localCompletedQuizzes = {};

  List<LessonModel> get lessons => _lessons;
  List<LessonModel> get localLessons => _localLessons;
  LessonModel? get currentLesson => _currentLesson;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNetworkConnection => _hasNetworkConnection;

  bool isUnitLoading(int unit) => _unitLoadingStates[unit] ?? false;
  bool isUnitLoaded(int unit) => _unitLoadedStates[unit] ?? false;
  List<LessonModel> getLessonsForUnit(int unit) => _lessonsByUnit[unit] ?? [];
  
  /// تحميل تدريجي للدروس مع أولوية للوحدة المطلوبة
  Future<void> loadLessonsProgressively({int? targetUnit, bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🚀 بدء التحميل التدريجي للدروس (الوحدة المستهدفة: $targetUnit)');
      
      // المرحلة 1: تحميل الدروس المحلية فوراً
      await _loadLocalLessonsInstantly();
      
      // المرحلة 2: تحديد الوحدة المستهدفة
      final currentUnit = targetUnit ?? _determineCurrentUnit();
      
      // المرحلة 3: تحميل الوحدة الحالية بأولوية عالية
      await _loadUnitProgressively(currentUnit, priority: true);
      
      // المرحلة 4: تحميل الوحدات المجاورة في الخلفية
      _preloadAdjacentUnits(currentUnit);
      
    } catch (e) {
      _setError('فشل في التحميل التدريجي للدروس: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل وحدة معينة بشكل تدريجي
  Future<void> _loadUnitProgressively(int unit, {bool priority = false}) async {
    if (_unitLoadingStates[unit] == true) {
      print('⏳ الوحدة $unit قيد التحميل بالفعل');
      return;
    }
    
    if (_unitLoadedStates[unit] == true && !priority) {
      print('✅ الوحدة $unit محملة بالفعل');
      return;
    }
    
    try {
      _unitLoadingStates[unit] = true;
      notifyListeners();
      
      print('📚 بدء تحميل الوحدة $unit (أولوية: $priority)');
      
      // تحميل من الكاش أولاً
      final cachedLessons = await _loadUnitFromCache(unit);
      if (cachedLessons.isNotEmpty) {
        _lessonsByUnit[unit] = cachedLessons;
        _unitLoadedStates[unit] = true;
        _updateMainLessonsList();
        notifyListeners();
        print('📦 تم تحميل ${cachedLessons.length} درس من الكاش للوحدة $unit');
      }
      
      // تحميل من Firebase في الخلفية
      if (_hasNetworkConnection) {
        await _loadUnitFromFirebase(unit, priority: priority);
      }
      
    } catch (e) {
      print('❌ خطأ في تحميل الوحدة $unit: $e');
      _setError('فشل في تحميل الوحدة $unit');
    } finally {
      _unitLoadingStates[unit] = false;
      notifyListeners();
    }
  }

  /// تحميل وحدة من Firebase بشكل تدريجي
  Future<void> _loadUnitFromFirebase(int unit, {bool priority = false}) async {
    try {
      final timeout = priority ? Duration(seconds: 10) : Duration(seconds: 30);
      
      print('🔄 تحميل الوحدة $unit من Firebase...');
      
      final firebaseLessons = await FirebaseService.getLessons(unit: unit)
          .timeout(timeout, onTimeout: () => <LessonModel>[]);
      
      if (firebaseLessons.isNotEmpty) {
        // دمج مع الدروس المحلية
        final existingLessons = _lessonsByUnit[unit] ?? [];
        final mergedLessons = _mergeLessons(existingLessons, firebaseLessons);
        
        _lessonsByUnit[unit] = mergedLessons;
        _unitLoadedStates[unit] = true;
        
        // تحديث القائمة الرئيسية
        _updateMainLessonsList();
        
        // حفظ في الكاش
        await _cacheUnitLessons(unit, mergedLessons);
        
        notifyListeners();
        print('✅ تم تحميل ${firebaseLessons.length} درس من Firebase للوحدة $unit');
      }
      
    } catch (e) {
      print('⚠️ فشل تحميل الوحدة $unit من Firebase: $e');
    }
  }

  /// تحميل مسبق للوحدات المجاورة
  Future<void> _preloadAdjacentUnits(int currentUnit) async {
    if (!_hasNetworkConnection) return;
    
    final unitsToPreload = <int>[];
    
    // الوحدة التالية
    if (currentUnit > 1) {
      unitsToPreload.add(currentUnit - 1);
    }
    unitsToPreload.add(currentUnit + 1);
    
    // تحديد الوحدات التي تحتاج تحميل مسبق
    final filteredUnits = unitsToPreload
        .where((unit) => !_unitLoadedStates.containsKey(unit) && 
                        !_preloadingUnits.contains(unit))
        .take(_maxPreloadUnits)
        .toList();
    
    for (final unit in filteredUnits) {
      _preloadingUnits.add(unit);
      
      // تحميل في الخلفية بدون انتظار
      _loadUnitProgressively(unit, priority: false).then((_) {
        _preloadingUnits.remove(unit);
      }).catchError((e) {
        _preloadingUnits.remove(unit);
        print('⚠️ فشل التحميل المسبق للوحدة $unit: $e');
      });
    }
    
    if (filteredUnits.isNotEmpty) {
      print('🔄 بدء التحميل المسبق للوحدات: $filteredUnits');
    }
  }

  /// تحميل وحدة من الكاش
  Future<List<LessonModel>> _loadUnitFromCache(int unit) async {
    try {
      return await CacheService.getCachedLessons(unit: unit, prioritizeRecent: true);
    } catch (e) {
      print('⚠️ فشل تحميل الوحدة $unit من الكاش: $e');
      return [];
    }
  }

  /// حفظ دروس الوحدة في الكاش
  Future<void> _cacheUnitLessons(int unit, List<LessonModel> lessons) async {
    try {
      // حفظ كل درس منفرداً للوصول السريع
      for (final lesson in lessons) {
        await CacheService.cacheLesson(lesson);
      }
      
      // حفظ قائمة الوحدة
      await CacheService.cacheLessons(lessons);
    } catch (e) {
      print('⚠️ فشل حفظ دروس الوحدة $unit في الكاش: $e');
    }
  }

  /// دمج قوائم الدروس مع تجنب التكرار
  List<LessonModel> _mergeLessons(List<LessonModel> existing, List<LessonModel> newLessons) {
    final mergedMap = <String, LessonModel>{};
    
    // إضافة الدروس الموجودة
    for (final lesson in existing) {
      mergedMap[lesson.id] = lesson;
    }
    
    // إضافة الدروس الجديدة (تحديث إذا كانت موجودة)
    for (final lesson in newLessons) {
      mergedMap[lesson.id] = lesson;
    }
    
    final merged = mergedMap.values.toList();
    
    // ترتيب حسب الترتيب
    merged.sort((a, b) => a.order.compareTo(b.order));
    
    return merged;
  }

  /// تحديث القائمة الرئيسية للدروس
  void _updateMainLessonsList() {
    final allLessons = <LessonModel>[];
    
    // إضافة الدروس المحلية
    allLessons.addAll(_localLessons);
    
    // إضافة دروس جميع الوحدات المحملة
    for (final unitLessons in _lessonsByUnit.values) {
      for (final lesson in unitLessons) {
        if (!allLessons.any((l) => l.id == lesson.id)) {
          allLessons.add(lesson);
        }
      }
    }
    
    // ترتيب نهائي
    allLessons.sort((a, b) {
      if (a.unit != b.unit) return a.unit.compareTo(b.unit);
      return a.order.compareTo(b.order);
    });
    
    _lessons = allLessons;
  }

  /// تحديد الوحدة الحالية للمستخدم
  int _determineCurrentUnit() {
    if (_lessons.isEmpty && _localLessons.isEmpty) return 1;
    
    final allLessons = _lessons.isNotEmpty ? _lessons : _localLessons;
    final availableUnits = allLessons.map((l) => l.unit).toSet().toList()..sort();
    
    // إرجاع أول وحدة متاحة
    return availableUnits.isNotEmpty ? availableUnits.first : 1;
  }

  /// تحميل درس معين مع التحميل التدريجي للوحدة
  Future<void> loadLessonProgressively(String lessonId, String userId) async {
    try {
      print('🚀 بدء تحميل الدرس التدريجي: $lessonId');
      _setLoading(true);
      _clearError();
      
      // البحث في الدروس المحملة أولاً
      _currentLesson = _findLessonInLoadedData(lessonId);
      
      if (_currentLesson != null) {
        print('✅ تم العثور على الدرس في البيانات المحملة: ${_currentLesson!.title}');
        notifyListeners();
        return;
      }
      
      // البحث في الدروس المحلية
      _currentLesson = await LocalService.getLocalLesson(lessonId);
      
      if (_currentLesson != null) {
        print('✅ تم العثور على الدرس محلياً: ${_currentLesson!.title}');
        
        // تحميل وحدة الدرس في الخلفية
        _loadUnitProgressively(_currentLesson!.unit, priority: false);
        
        notifyListeners();
        return;
      }
      
      // البحث في الكاش
      _currentLesson = await CacheService.getCachedLesson(lessonId);
      
      if (_currentLesson != null) {
        print('✅ تم العثور على الدرس في الكاش: ${_currentLesson!.title}');
        
        // تحميل وحدة الدرس في الخلفية
        _loadUnitProgressively(_currentLesson!.unit, priority: false);
        
        notifyListeners();
        return;
      }
      
      // البحث في Firebase كملاذ أخير
      if (_hasNetworkConnection) {
        _currentLesson = await FirebaseService.getLesson(lessonId)
            .timeout(Duration(seconds: 10), onTimeout: () => null);
        
        if (_currentLesson != null) {
          print('✅ تم العثور على الدرس في Firebase: ${_currentLesson!.title}');
          
          // حفظ في الكاش للمرات القادمة
          await CacheService.cacheLesson(_currentLesson!);
          
          // تحميل وحدة الدرس
          _loadUnitProgressively(_currentLesson!.unit, priority: true);
        } else {
          print('❌ لم يتم العثور على الدرس في أي مكان');
          _setError('لم يتم العثور على الدرس المطلوب');
        }
      } else {
        _setError('لا يوجد اتصال بالإنترنت ولم يتم العثور على الدرس محلياً');
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في تحميل الدرس التدريجي: $e');
      _setError('فشل في تحميل الدرس: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// البحث عن درس في البيانات المحملة
  LessonModel? _findLessonInLoadedData(String lessonId) {
    // البحث في القائمة الرئيسية
    for (final lesson in _lessons) {
      if (lesson.id == lessonId) return lesson;
    }
    
    // البحث في الدروس المحلية
    for (final lesson in _localLessons) {
      if (lesson.id == lessonId) return lesson;
    }
    
    // البحث في دروس الوحدات
    for (final unitLessons in _lessonsByUnit.values) {
      for (final lesson in unitLessons) {
        if (lesson.id == lessonId) return lesson;
      }
    }
    
    return null;
  }

  /// تحميل وحدة معينة عند الطلب
  Future<void> loadUnitOnDemand(int unit) async {
    if (_unitLoadedStates[unit] == true) {
      print('✅ الوحدة $unit محملة بالفعل');
      return;
    }
    
    await _loadUnitProgressively(unit, priority: true);
  }

  /// الحصول على حالة التحميل للوحدات
  Map<int, LoadingState> getUnitsLoadingState() {
    final state = <int, LoadingState>{};
    
    for (int unit = 1; unit <= 10; unit++) { // افتراض وجود 10 وحدات كحد أقصى
      if (_unitLoadingStates[unit] == true) {
        state[unit] = LoadingState.loading;
      } else if (_unitLoadedStates[unit] == true) {
        state[unit] = LoadingState.loaded;
      } else {
        state[unit] = LoadingState.notLoaded;
      }
    }
    
    return state;
  }

  /// تحسين الذاكرة بإزالة الوحدات غير المستخدمة
  Future<void> optimizeMemory() async {
    try {
      print('🧹 بدء تحسين الذاكرة...');
      
      final currentUnit = _determineCurrentUnit();
      final unitsToKeep = {currentUnit - 1, currentUnit, currentUnit + 1};
      
      final unitsToRemove = _lessonsByUnit.keys
          .where((unit) => !unitsToKeep.contains(unit))
          .toList();
      
      for (final unit in unitsToRemove) {
        _lessonsByUnit.remove(unit);
        _unitLoadedStates.remove(unit);
        print('🗑️ تم إزالة الوحدة $unit من الذاكرة');
      }
      
      // تحديث القائمة الرئيسية
      _updateMainLessonsList();
      
      // تحسين كاش النظام
      await CacheService.optimizeCache();
      
      notifyListeners();
      print('✅ تم تحسين الذاكرة بنجاح');
    } catch (e) {
      print('❌ خطأ في تحسين الذاكرة: $e');
    }
  }

  /// تحميل فوري للدروس مع أولوية للمحتوى المحلي
  @deprecated
  Future<void> loadLessons({int? unit, bool forceRefresh = false}) async {
    // إعادة توجيه للتحميل التدريجي
    await loadLessonsProgressively(targetUnit: unit, forceRefresh: forceRefresh);
  }

  /// تحميل الدروس المحلية فوراً
  Future<void> _loadLocalLessonsInstantly({int? unit}) async {
    try {
      _localLessons = await LocalService.getLocalLessons(unit: unit);
      
      // تنظيم الدروس المحلية حسب الوحدات
      final localByUnit = <int, List<LessonModel>>{};
      for (final lesson in _localLessons) {
        localByUnit.putIfAbsent(lesson.unit, () => []).add(lesson);
      }
      
      // دمج مع البيانات الموجودة
      for (final entry in localByUnit.entries) {
        final unit = entry.key;
        final lessons = entry.value;
        
        if (_lessonsByUnit.containsKey(unit)) {
          _lessonsByUnit[unit] = _mergeLessons(_lessonsByUnit[unit]!, lessons);
        } else {
          _lessonsByUnit[unit] = lessons;
          _unitLoadedStates[unit] = true;
        }
      }
      
      _updateMainLessonsList();
      
      // تحميل التقدم المحلي
      await _loadLocalProgress();
      
      // إشعار فوري لعرض الدروس
      notifyListeners();
      
      print('✅ تم تحميل ${_localLessons.length} درس محلي');
    } catch (e) {
      _localLessons = [];
      print('❌ خطأ في تحميل الدروس المحلية: $e');
    }
  }

  /// تحميل من الكاش إذا متوفر
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
  List<LessonModel> getAvailableLessons(List<String> completedQuizzes, int currentUnit) {
    if (_lessons.isEmpty) {
      return [];
    }
    
    // دمج الاختبارات المكتملة مع التقدم المحلي
    final allCompletedQuizzes = <String>{};
    allCompletedQuizzes.addAll(completedQuizzes);
    allCompletedQuizzes.addAll(_localCompletedQuizzes);
    
    // الحصول على الوحدة الحالية للمستخدم
    int userCurrentUnit = _getUserCurrentUnit(allCompletedQuizzes);
    
    final availableLessons = _lessons.where((lesson) {
      // عرض دروس الوحدة الحالية فقط
      return lesson.unit == userCurrentUnit;
    }).toList();
    
    // ترتيب الدروس حسب الترتيب
    availableLessons.sort((a, b) => a.order.compareTo(b.order));
    
    return availableLessons;
  }

  /// تحديد الوحدة الحالية للمستخدم
  int _getUserCurrentUnit(Set<String> completedQuizzes) {
    if (_lessons.isEmpty) return 1;
    
    // الحصول على جميع الوحدات المتاحة
    final availableUnits = _lessons.map((l) => l.unit).toSet().toList()..sort();
    
    for (int unit in availableUnits) {
      // الحصول على دروس هذه الوحدة
      final unitLessons = _lessons.where((l) => l.unit == unit).toList();
      
      // التحقق من إكمال جميع اختبارات الوحدة
      final completedInUnit = unitLessons.where((l) => completedQuizzes.contains(l.id)).length;
      
      // إذا لم تكتمل الوحدة، فهي الوحدة الحالية
      if (completedInUnit < unitLessons.length) {
        return unit;
      }
    }
    
    // إذا اكتملت جميع الوحدات، عرض الوحدة التالية إن وجدت
    final maxUnit = availableUnits.isNotEmpty ? availableUnits.last : 1;
    return maxUnit + 1;
  }

  /// الحصول على معلومات الوحدات للعرض
  List<UnitInfo> getUnitsInfo(List<String> completedQuizzes) {
    if (_lessons.isEmpty) return [];
    
    final allCompletedQuizzes = <String>{};
    allCompletedQuizzes.addAll(completedQuizzes);
    allCompletedQuizzes.addAll(_localCompletedQuizzes);
    
    final availableUnits = _lessons.map((l) => l.unit).toSet().toList()..sort();
    final unitsInfo = <UnitInfo>[];
    
    for (int unit in availableUnits) {
      final unitLessons = _lessons.where((l) => l.unit == unit).toList();
      final completedCount = unitLessons.where((l) => allCompletedQuizzes.contains(l.id)).length;
      final isCompleted = completedCount == unitLessons.length;
      final isUnlocked = unit == 1 || (unit > 1 && unitsInfo.isNotEmpty && unitsInfo.last.isCompleted);
      
      // تحديد حالة كل درس
      final lessonsWithStatus = unitLessons.map((lesson) {
        LessonStatus status;
        if (lesson.unit == 1 && lesson.order == 1) {
          // الدرس الأول دائماً مفتوح
          status = LessonStatus.open;
        } else if (allCompletedQuizzes.contains(lesson.id)) {
          // الدرس مكتمل
          status = LessonStatus.completed;
        } else {
          // فحص إذا كان الدرس السابق مكتمل
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
        lessons: unitLessons,
        lessonsWithStatus: lessonsWithStatus,
      ));
    }
    
    return unitsInfo;
  }

  /// الحصول على الدرس السابق
  LessonModel? _getPreviousLesson(LessonModel lesson) {
    final unitLessons = _lessons.where((l) => l.unit == lesson.unit).toList();
    unitLessons.sort((a, b) => a.order.compareTo(b.order));
    
    final currentIndex = unitLessons.indexWhere((l) => l.id == lesson.id);
    if (currentIndex > 0) {
      return unitLessons[currentIndex - 1];
    }
    
    // إذا كان أول درس في الوحدة، فحص آخر درس في الوحدة السابقة
    if (lesson.unit > 1) {
      final previousUnitLessons = _lessons.where((l) => l.unit == lesson.unit - 1).toList();
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

  /// تحميل درس معين مع أولوية للمحتوى المحلي
  Future<void> loadLesson(String lessonId, String userId) async {
    try {
      print('🚀 بدء تحميل الدرس: $lessonId للمستخدم: $userId');
      _setLoading(true);
      _clearError();
      
      // البحث في الدروس المحلية أولاً
      print('🔍 البحث في الدروس المحلية...');
      _currentLesson = await LocalService.getLocalLesson(lessonId);
      
      if (_currentLesson != null) {
        print('✅ تم العثور على الدرس محلياً: ${_currentLesson!.title}');
        print('❓ عدد أسئلة الاختبار: ${_currentLesson!.quiz.length}');
        
        // طباعة تفاصيل الأسئلة للتأكد
        for (int i = 0; i < _currentLesson!.quiz.length; i++) {
          final question = _currentLesson!.quiz[i];
          print('❓ السؤال ${i + 1}: ${question.question}');
          print('   الخيارات: ${question.options.length}');
        }
      } else {
        print('⚠️ لم يتم العثور على الدرس محلياً، البحث في Firebase...');
        // البحث في Firebase
        _currentLesson = await FirebaseService.getLesson(lessonId);
        
        if (_currentLesson != null) {
          print('✅ تم العثور على الدرس في Firebase: ${_currentLesson!.title}');
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

/// حالة التحميل للوحدات
enum LoadingState {
  notLoaded,
  loading,
  loaded,
}
