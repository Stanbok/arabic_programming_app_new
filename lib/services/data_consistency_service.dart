import 'dart:async';
import '../models/lesson_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'cache_service.dart';
import 'local_service.dart';

/// خدمة ضمان اتساق البيانات
class DataConsistencyService {
  static final DataConsistencyService _instance = DataConsistencyService._internal();
  factory DataConsistencyService() => _instance;
  DataConsistencyService._internal();

  Timer? _consistencyCheckTimer;
  final List<ConsistencyIssue> _detectedIssues = [];
  
  static const Duration _checkInterval = Duration(hours: 1);

  /// تهيئة خدمة اتساق البيانات
  Future<void> initialize() async {
    await _performInitialConsistencyCheck();
    _startPeriodicConsistencyCheck();
    print('🔍 تم تهيئة خدمة ضمان اتساق البيانات');
  }

  /// بدء الفحص الدوري للاتساق
  void _startPeriodicConsistencyCheck() {
    _consistencyCheckTimer = Timer.periodic(_checkInterval, (timer) {
      _performConsistencyCheck();
    });
  }

  /// فحص الاتساق الأولي
  Future<void> _performInitialConsistencyCheck() async {
    try {
      await _performConsistencyCheck();
      print('✅ تم إجراء فحص الاتساق الأولي');
    } catch (e) {
      print('❌ خطأ في فحص الاتساق الأولي: $e');
    }
  }

  /// فحص اتساق البيانات
  Future<void> _performConsistencyCheck() async {
    try {
      _detectedIssues.clear();
      
      // فحص اتساق الدروس
      await _checkLessonsConsistency();
      
      // فحص اتساق الوحدات
      await _checkUnitsConsistency();
      
      // فحص اتساق الكاش
      await _checkCacheConsistency();
      
      // إصلاح المشاكل البسيطة تلقائياً
      await _autoFixMinorIssues();
      
      if (_detectedIssues.isNotEmpty) {
        print('⚠️ تم اكتشاف ${_detectedIssues.length} مشكلة في اتساق البيانات');
      }
      
    } catch (e) {
      print('❌ خطأ في فحص اتساق البيانات: $e');
    }
  }

  /// فحص اتساق الدروس
  Future<void> _checkLessonsConsistency() async {
    try {
      // جلب الدروس من مصادر مختلفة
      final localLessons = await LocalService.getLocalLessons();
      final cachedLessons = await CacheService.getCachedLessons();
      
      // فحص التطابق في المعرفات
      final localIds = localLessons.map((l) => l.id).toSet();
      final cachedIds = cachedLessons.map((l) => l.id).toSet();
      
      // البحث عن دروس مفقودة في الكاش
      final missingInCache = localIds.difference(cachedIds);
      if (missingInCache.isNotEmpty) {
        _detectedIssues.add(ConsistencyIssue(
          type: IssueType.missingInCache,
          description: 'دروس مفقودة في الكاش: ${missingInCache.join(', ')}',
          severity: IssueSeverity.medium,
          affectedItems: missingInCache.toList(),
        ));
      }
      
      // فحص تطابق بيانات الدروس
      for (final localLesson in localLessons) {
        final cachedLesson = cachedLessons.firstWhere(
          (l) => l.id == localLesson.id,
          orElse: () => LessonModel(
            id: '',
            title: '',
            description: '',
            unit: 0,
            order: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        if (cachedLesson.id.isNotEmpty) {
          // فحص تطابق الوحدة
          if (localLesson.unit != cachedLesson.unit) {
            _detectedIssues.add(ConsistencyIssue(
              type: IssueType.unitMismatch,
              description: 'عدم تطابق الوحدة للدرس ${localLesson.id}: محلي=${localLesson.unit}, كاش=${cachedLesson.unit}',
              severity: IssueSeverity.high,
              affectedItems: [localLesson.id],
            ));
          }
          
          // فحص تطابق الترتيب
          if (localLesson.order != cachedLesson.order) {
            _detectedIssues.add(ConsistencyIssue(
              type: IssueType.orderMismatch,
              description: 'عدم تطابق الترتيب للدرس ${localLesson.id}: محلي=${localLesson.order}, كاش=${cachedLesson.order}',
              severity: IssueSeverity.medium,
              affectedItems: [localLesson.id],
            ));
          }
        }
      }
      
    } catch (e) {
      print('❌ خطأ في فحص اتساق الدروس: $e');
    }
  }

  /// فحص اتساق الوحدات
  Future<void> _checkUnitsConsistency() async {
    try {
      final allLessons = await CacheService.getCachedLessons();
      
      // تجميع الدروس حسب الوحدة
      final unitGroups = <int, List<LessonModel>>{};
      for (final lesson in allLessons) {
        unitGroups.putIfAbsent(lesson.unit, () => []).add(lesson);
      }
      
      // فحص تسلسل الوحدات
      final units = unitGroups.keys.toList()..sort();
      for (int i = 0; i < units.length - 1; i++) {
        if (units[i + 1] - units[i] > 1) {
          _detectedIssues.add(ConsistencyIssue(
            type: IssueType.unitGap,
            description: 'فجوة في تسلسل الوحدات: من ${units[i]} إلى ${units[i + 1]}',
            severity: IssueSeverity.medium,
            affectedItems: ['unit_${units[i]}', 'unit_${units[i + 1]}'],
          ));
        }
      }
      
      // فحص ترتيب الدروس داخل كل وحدة
      for (final entry in unitGroups.entries) {
        final unitLessons = entry.value..sort((a, b) => a.order.compareTo(b.order));
        
        for (int i = 0; i < unitLessons.length - 1; i++) {
          if (unitLessons[i + 1].order - unitLessons[i].order > 1) {
            _detectedIssues.add(ConsistencyIssue(
              type: IssueType.orderGap,
              description: 'فجوة في ترتيب الدروس في الوحدة ${entry.key}: من ${unitLessons[i].order} إلى ${unitLessons[i + 1].order}',
              severity: IssueSeverity.low,
              affectedItems: [unitLessons[i].id, unitLessons[i + 1].id],
            ));
          }
        }
      }
      
    } catch (e) {
      print('❌ خطأ في فحص اتساق الوحدات: $e');
    }
  }

  /// فحص اتساق الكاش
  Future<void> _checkCacheConsistency() async {
    try {
      final cacheInfo = await CacheService.getCacheInfo();
      
      // فحص صحة الكاش
      if (!cacheInfo.isValid && cacheInfo.totalLessons > 0) {
        _detectedIssues.add(ConsistencyIssue(
          type: IssueType.invalidCache,
          description: 'الكاش غير صالح ولكن يحتوي على ${cacheInfo.totalLessons} درس',
          severity: IssueSeverity.medium,
          affectedItems: ['cache'],
        ));
      }
      
      // فحص حجم الكاش
      if (cacheInfo.dataSize > 100 * 1024 * 1024) { // أكثر من 100MB
        _detectedIssues.add(ConsistencyIssue(
          type: IssueType.largeCacheSize,
          description: 'حجم الكاش كبير جداً: ${cacheInfo.formattedSize}',
          severity: IssueSeverity.low,
          affectedItems: ['cache'],
        ));
      }
      
    } catch (e) {
      print('❌ خطأ في فحص اتساق الكاش: $e');
    }
  }

  /// إصلاح المشاكل البسيطة تلقائياً
  Future<void> _autoFixMinorIssues() async {
    final fixableIssues = _detectedIssues.where((issue) => 
        issue.severity == IssueSeverity.low && 
        (issue.type == IssueType.invalidCache || issue.type == IssueType.largeCacheSize)
    ).toList();
    
    for (final issue in fixableIssues) {
      try {
        switch (issue.type) {
          case IssueType.invalidCache:
            await CacheService.clearCache();
            print('🔧 تم إصلاح الكاش غير الصالح');
            break;
          case IssueType.largeCacheSize:
            await CacheService.cleanupOldCache();
            print('🔧 تم تنظيف الكاش الكبير');
            break;
          default:
            break;
        }
        
        _detectedIssues.remove(issue);
      } catch (e) {
        print('❌ فشل إصلاح المشكلة ${issue.type}: $e');
      }
    }
  }

  /// إصلاح مشكلة معينة
  Future<bool> fixIssue(ConsistencyIssue issue) async {
    try {
      switch (issue.type) {
        case IssueType.missingInCache:
          // إعادة تحميل الدروس المفقودة
          final localLessons = await LocalService.getLocalLessons();
          final missingLessons = localLessons.where((l) => 
              issue.affectedItems.contains(l.id)).toList();
          
          for (final lesson in missingLessons) {
            await CacheService.cacheLesson(lesson);
          }
          break;
          
        case IssueType.unitMismatch:
        case IssueType.orderMismatch:
          // إعادة بناء الكاش من البيانات المحلية
          await CacheService.clearCache();
          final allLessons = await LocalService.getLocalLessons();
          await CacheService.cacheLessons(allLessons);
          break;
          
        case IssueType.invalidCache:
          await CacheService.clearCache();
          break;
          
        case IssueType.largeCacheSize:
          await CacheService.cleanupOldCache();
          break;
          
        default:
          return false;
      }
      
      _detectedIssues.remove(issue);
      print('✅ تم إصلاح المشكلة: ${issue.description}');
      return true;
      
    } catch (e) {
      print('❌ فشل إصلاح المشكلة: $e');
      return false;
    }
  }

  /// إصلاح جميع المشاكل
  Future<int> fixAllIssues() async {
    int fixedCount = 0;
    final issuesToFix = List<ConsistencyIssue>.from(_detectedIssues);
    
    for (final issue in issuesToFix) {
      if (await fixIssue(issue)) {
        fixedCount++;
      }
    }
    
    print('🔧 تم إصلاح $fixedCount من ${issuesToFix.length} مشكلة');
    return fixedCount;
  }

  /// الحصول على تقرير الاتساق
  ConsistencyReport getConsistencyReport() {
    final issuesBySeverity = <IssueSeverity, int>{};
    for (final issue in _detectedIssues) {
      issuesBySeverity[issue.severity] = (issuesBySeverity[issue.severity] ?? 0) + 1;
    }
    
    return ConsistencyReport(
      totalIssues: _detectedIssues.length,
      issuesBySeverity: issuesBySeverity,
      issues: List.from(_detectedIssues),
      lastCheckTime: DateTime.now(),
      isHealthy: _detectedIssues.where((i) => i.severity == IssueSeverity.high).isEmpty,
    );
  }

  /// تنظيف الموارد
  void dispose() {
    _consistencyCheckTimer?.cancel();
  }

  // Getters
  List<ConsistencyIssue> get detectedIssues => List.from(_detectedIssues);
  bool get hasIssues => _detectedIssues.isNotEmpty;
  bool get hasHighSeverityIssues => _detectedIssues.any((i) => i.severity == IssueSeverity.high);
}

/// مشكلة في اتساق البيانات
class ConsistencyIssue {
  final IssueType type;
  final String description;
  final IssueSeverity severity;
  final List<String> affectedItems;
  final DateTime detectedAt;

  ConsistencyIssue({
    required this.type,
    required this.description,
    required this.severity,
    required this.affectedItems,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();
}

/// نوع المشكلة
enum IssueType {
  missingInCache,
  unitMismatch,
  orderMismatch,
  unitGap,
  orderGap,
  invalidCache,
  largeCacheSize,
}

/// شدة المشكلة
enum IssueSeverity {
  low,
  medium,
  high,
}

/// تقرير الاتساق
class ConsistencyReport {
  final int totalIssues;
  final Map<IssueSeverity, int> issuesBySeverity;
  final List<ConsistencyIssue> issues;
  final DateTime lastCheckTime;
  final bool isHealthy;

  ConsistencyReport({
    required this.totalIssues,
    required this.issuesBySeverity,
    required this.issues,
    required this.lastCheckTime,
    required this.isHealthy,
  });

  int get highSeverityIssues => issuesBySeverity[IssueSeverity.high] ?? 0;
  int get mediumSeverityIssues => issuesBySeverity[IssueSeverity.medium] ?? 0;
  int get lowSeverityIssues => issuesBySeverity[IssueSeverity.low] ?? 0;

  String get healthStatus {
    if (isHealthy) return 'سليم';
    if (highSeverityIssues > 0) return 'يحتاج إصلاح فوري';
    if (mediumSeverityIssues > 0) return 'يحتاج مراجعة';
    return 'مشاكل بسيطة';
  }
}
