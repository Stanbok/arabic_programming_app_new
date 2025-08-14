import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_model.dart';

/// خدمة إدارة الأداء والذاكرة المتقدمة
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // مراقبة الذاكرة
  final Map<String, DateTime> _memoryUsageLog = {};
  final Map<String, int> _operationCounts = {};
  final List<PerformanceMetric> _performanceMetrics = [];
  
  // إعدادات الأداء
  static const int _maxCachedItems = 50;
  static const int _maxPerformanceMetrics = 100;
  static const Duration _memoryCleanupInterval = Duration(minutes: 10);
  static const Duration _performanceReportInterval = Duration(minutes: 30);
  
  // مؤقتات التنظيف
  Timer? _memoryCleanupTimer;
  Timer? _performanceReportTimer;
  
  // إحصائيات الأداء
  int _totalOperations = 0;
  int _successfulOperations = 0;
  int _failedOperations = 0;
  double _averageResponseTime = 0.0;

  /// تهيئة خدمة الأداء
  Future<void> initialize() async {
    await _loadPerformanceData();
    _startPerformanceMonitoring();
    _startMemoryCleanup();
    
    print('🚀 تم تهيئة خدمة إدارة الأداء');
  }

  /// بدء مراقبة الأداء
  void _startPerformanceMonitoring() {
    _performanceReportTimer = Timer.periodic(_performanceReportInterval, (timer) {
      _generatePerformanceReport();
    });
  }

  /// بدء تنظيف الذاكرة التلقائي
  void _startMemoryCleanup() {
    _memoryCleanupTimer = Timer.periodic(_memoryCleanupInterval, (timer) {
      _performMemoryCleanup();
    });
  }

  /// قياس أداء العملية
  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    bool logResult = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      _totalOperations++;
      _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
      
      final result = await operation();
      
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      
      _successfulOperations++;
      _updateAverageResponseTime(duration.toDouble());
      
      if (logResult) {
        _logPerformanceMetric(PerformanceMetric(
          operationName: operationName,
          duration: duration,
          timestamp: startTime,
          success: true,
          memoryUsage: await _getCurrentMemoryUsage(),
        ));
      }
      
      print('⚡ $operationName: ${duration}ms');
      return result;
      
    } catch (e) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      
      _failedOperations++;
      
      if (logResult) {
        _logPerformanceMetric(PerformanceMetric(
          operationName: operationName,
          duration: duration,
          timestamp: startTime,
          success: false,
          error: e.toString(),
          memoryUsage: await _getCurrentMemoryUsage(),
        ));
      }
      
      print('❌ $operationName فشل في ${duration}ms: $e');
      rethrow;
    }
  }

  /// تسجيل مقياس الأداء
  void _logPerformanceMetric(PerformanceMetric metric) {
    _performanceMetrics.add(metric);
    
    // الحفاظ على حد أقصى من المقاييس
    if (_performanceMetrics.length > _maxPerformanceMetrics) {
      _performanceMetrics.removeRange(0, _performanceMetrics.length - _maxPerformanceMetrics);
    }
  }

  /// تحديث متوسط وقت الاستجابة
  void _updateAverageResponseTime(double newTime) {
    if (_successfulOperations == 1) {
      _averageResponseTime = newTime;
    } else {
      _averageResponseTime = ((_averageResponseTime * (_successfulOperations - 1)) + newTime) / _successfulOperations;
    }
  }

  /// الحصول على استخدام الذاكرة الحالي
  Future<int> _getCurrentMemoryUsage() async {
    if (kIsWeb) return 0; // لا يمكن قياس الذاكرة في الويب
    
    try {
      final info = ProcessInfo.currentRss;
      return info;
    } catch (e) {
      return 0;
    }
  }

  /// تنظيف الذاكرة
  Future<void> _performMemoryCleanup() async {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];
      
      // البحث عن العناصر المنتهية الصلاحية
      for (final entry in _memoryUsageLog.entries) {
        if (now.difference(entry.value).inMinutes > 30) {
          expiredKeys.add(entry.key);
        }
      }
      
      // إزالة العناصر المنتهية الصلاحية
      for (final key in expiredKeys) {
        _memoryUsageLog.remove(key);
      }
      
      // تنظيف مقاييس الأداء القديمة
      _performanceMetrics.removeWhere((metric) => 
          now.difference(metric.timestamp).inHours > 24);
      
      // إجبار جمع القمامة إذا لزم الأمر
      if (expiredKeys.length > 10) {
        _forceGarbageCollection();
      }
      
      if (expiredKeys.isNotEmpty) {
        print('🧹 تم تنظيف ${expiredKeys.length} عنصر من الذاكرة');
      }
      
    } catch (e) {
      print('❌ خطأ في تنظيف الذاكرة: $e');
    }
  }

  /// إجبار جمع القمامة
  void _forceGarbageCollection() {
    if (!kIsWeb) {
      // محاولة تحرير الذاكرة
      System.gc();
    }
  }

  /// إنشاء تقرير الأداء
  void _generatePerformanceReport() {
    final report = PerformanceReport(
      totalOperations: _totalOperations,
      successfulOperations: _successfulOperations,
      failedOperations: _failedOperations,
      averageResponseTime: _averageResponseTime,
      operationCounts: Map.from(_operationCounts),
      recentMetrics: _performanceMetrics.take(20).toList(),
      timestamp: DateTime.now(),
    );
    
    _savePerformanceReport(report);
    
    if (kDebugMode) {
      print('📊 تقرير الأداء:');
      print('   العمليات الكلية: ${report.totalOperations}');
      print('   العمليات الناجحة: ${report.successfulOperations}');
      print('   العمليات الفاشلة: ${report.failedOperations}');
      print('   متوسط وقت الاستجابة: ${report.averageResponseTime.toStringAsFixed(2)}ms');
      print('   معدل النجاح: ${report.successRate.toStringAsFixed(1)}%');
    }
  }

  /// حفظ تقرير الأداء
  Future<void> _savePerformanceReport(PerformanceReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_performance_report', report.toJson());
    } catch (e) {
      print('❌ خطأ في حفظ تقرير الأداء: $e');
    }
  }

  /// تحميل بيانات الأداء
  Future<void> _loadPerformanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportData = prefs.getString('last_performance_report');
      
      if (reportData != null) {
        final report = PerformanceReport.fromJson(reportData);
        _totalOperations = report.totalOperations;
        _successfulOperations = report.successfulOperations;
        _failedOperations = report.failedOperations;
        _averageResponseTime = report.averageResponseTime;
        _operationCounts.addAll(report.operationCounts);
      }
    } catch (e) {
      print('❌ خطأ في تحميل بيانات الأداء: $e');
    }
  }

  /// تحسين أداء قائمة الدروس
  List<LessonModel> optimizeLessonsList(List<LessonModel> lessons) {
    // ترتيب الدروس مرة واحدة
    lessons.sort((a, b) {
      if (a.unit != b.unit) return a.unit.compareTo(b.unit);
      return a.order.compareTo(b.order);
    });
    
    // إزالة التكرارات
    final uniqueLessons = <String, LessonModel>{};
    for (final lesson in lessons) {
      uniqueLessons[lesson.id] = lesson;
    }
    
    return uniqueLessons.values.toList();
  }

  /// تحسين عملية البحث في الدروس
  List<LessonModel> optimizedLessonSearch(
    List<LessonModel> lessons,
    String query, {
    int maxResults = 10,
  }) {
    if (query.isEmpty) return lessons.take(maxResults).toList();
    
    final lowerQuery = query.toLowerCase();
    final results = <LessonModel>[];
    
    // البحث بالأولوية: العنوان أولاً، ثم الوصف
    for (final lesson in lessons) {
      if (results.length >= maxResults) break;
      
      if (lesson.title.toLowerCase().contains(lowerQuery)) {
        results.add(lesson);
      }
    }
    
    // إضافة نتائج من الوصف إذا لم نصل للحد الأقصى
    if (results.length < maxResults) {
      for (final lesson in lessons) {
        if (results.length >= maxResults) break;
        
        if (!results.contains(lesson) && 
            lesson.description.toLowerCase().contains(lowerQuery)) {
          results.add(lesson);
        }
      }
    }
    
    return results;
  }

  /// تحسين تحميل الصور
  Future<void> preloadImages(List<String> imageUrls) async {
    final futures = <Future>[];
    
    for (final url in imageUrls.take(5)) { // تحميل 5 صور كحد أقصى
      futures.add(_preloadSingleImage(url));
    }
    
    await Future.wait(futures, eagerError: false);
  }

  /// تحميل صورة واحدة مسبقاً
  Future<void> _preloadSingleImage(String url) async {
    try {
      // هنا يمكن إضافة منطق تحميل الصورة مسبقاً
      // مثل استخدام cached_network_image
    } catch (e) {
      print('⚠️ فشل تحميل الصورة مسبقاً: $url');
    }
  }

  /// تحسين عمليات قاعدة البيانات
  Future<T> optimizedDatabaseOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    return await measureOperation(
      'db_$operationName',
      () async {
        // إضافة timeout للعمليات
        return await operation().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('انتهت مهلة العملية', const Duration(seconds: 30)),
        );
      },
    );
  }

  /// الحصول على إحصائيات الأداء
  PerformanceStats getPerformanceStats() {
    final recentMetrics = _performanceMetrics
        .where((m) => DateTime.now().difference(m.timestamp).inMinutes < 60)
        .toList();
    
    final avgRecentResponseTime = recentMetrics.isNotEmpty
        ? recentMetrics.map((m) => m.duration).reduce((a, b) => a + b) / recentMetrics.length
        : 0.0;
    
    return PerformanceStats(
      totalOperations: _totalOperations,
      successfulOperations: _successfulOperations,
      failedOperations: _failedOperations,
      successRate: _totalOperations > 0 ? (_successfulOperations / _totalOperations) * 100 : 0,
      averageResponseTime: _averageResponseTime,
      recentAverageResponseTime: avgRecentResponseTime,
      operationCounts: Map.from(_operationCounts),
      memoryUsageEntries: _memoryUsageLog.length,
      performanceMetricsCount: _performanceMetrics.length,
    );
  }

  /// إعادة تعيين الإحصائيات
  Future<void> resetStats() async {
    _totalOperations = 0;
    _successfulOperations = 0;
    _failedOperations = 0;
    _averageResponseTime = 0.0;
    _operationCounts.clear();
    _performanceMetrics.clear();
    _memoryUsageLog.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_performance_report');
    
    print('🔄 تم إعادة تعيين إحصائيات الأداء');
  }

  /// تنظيف الموارد
  void dispose() {
    _memoryCleanupTimer?.cancel();
    _performanceReportTimer?.cancel();
  }
}

/// مقياس الأداء
class PerformanceMetric {
  final String operationName;
  final int duration;
  final DateTime timestamp;
  final bool success;
  final String? error;
  final int memoryUsage;

  PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    required this.success,
    this.error,
    required this.memoryUsage,
  });

  Map<String, dynamic> toMap() {
    return {
      'operationName': operationName,
      'duration': duration,
      'timestamp': timestamp.toIso8601String(),
      'success': success,
      'error': error,
      'memoryUsage': memoryUsage,
    };
  }

  factory PerformanceMetric.fromMap(Map<String, dynamic> map) {
    return PerformanceMetric(
      operationName: map['operationName'] ?? '',
      duration: map['duration'] ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
      success: map['success'] ?? false,
      error: map['error'],
      memoryUsage: map['memoryUsage'] ?? 0,
    );
  }
}

/// تقرير الأداء
class PerformanceReport {
  final int totalOperations;
  final int successfulOperations;
  final int failedOperations;
  final double averageResponseTime;
  final Map<String, int> operationCounts;
  final List<PerformanceMetric> recentMetrics;
  final DateTime timestamp;

  PerformanceReport({
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.averageResponseTime,
    required this.operationCounts,
    required this.recentMetrics,
    required this.timestamp,
  });

  double get successRate => totalOperations > 0 ? (successfulOperations / totalOperations) * 100 : 0;

  String toJson() {
    return '''
    {
      "totalOperations": $totalOperations,
      "successfulOperations": $successfulOperations,
      "failedOperations": $failedOperations,
      "averageResponseTime": $averageResponseTime,
      "operationCounts": ${operationCounts.toString()},
      "timestamp": "${timestamp.toIso8601String()}"
    }
    ''';
  }

  factory PerformanceReport.fromJson(String json) {
    // تبسيط للمثال - في التطبيق الحقيقي يجب استخدام dart:convert
    return PerformanceReport(
      totalOperations: 0,
      successfulOperations: 0,
      failedOperations: 0,
      averageResponseTime: 0.0,
      operationCounts: {},
      recentMetrics: [],
      timestamp: DateTime.now(),
    );
  }
}

/// إحصائيات الأداء
class PerformanceStats {
  final int totalOperations;
  final int successfulOperations;
  final int failedOperations;
  final double successRate;
  final double averageResponseTime;
  final double recentAverageResponseTime;
  final Map<String, int> operationCounts;
  final int memoryUsageEntries;
  final int performanceMetricsCount;

  PerformanceStats({
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.successRate,
    required this.averageResponseTime,
    required this.recentAverageResponseTime,
    required this.operationCounts,
    required this.memoryUsageEntries,
    required this.performanceMetricsCount,
  });

  bool get isPerformanceGood => successRate > 90 && averageResponseTime < 1000;
  bool get isPerformancePoor => successRate < 70 || averageResponseTime > 3000;
  
  String get performanceGrade {
    if (isPerformanceGood) return 'ممتاز';
    if (isPerformancePoor) return 'ضعيف';
    return 'جيد';
  }
}
