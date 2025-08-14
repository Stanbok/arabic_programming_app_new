import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة مراقبة وتحسين الأداء
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // مراقبة الأداء
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, List<int>> _operationDurations = {};
  final Map<String, int> _operationCounts = {};
  
  // إعدادات الأداء
  static const int _maxOperationHistory = 100;
  static const int _performanceReportInterval = 300; // 5 دقائق
  static const int _memoryCleanupInterval = 600; // 10 دقائق
  
  Timer? _performanceTimer;
  Timer? _memoryCleanupTimer;
  bool _isMonitoring = false;

  /// بدء مراقبة الأداء
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // تقرير الأداء الدوري
    _performanceTimer = Timer.periodic(
      Duration(seconds: _performanceReportInterval),
      (_) => _generatePerformanceReport(),
    );
    
    // تنظيف الذاكرة الدوري
    _memoryCleanupTimer = Timer.periodic(
      Duration(seconds: _memoryCleanupInterval),
      (_) => _performMemoryCleanup(),
    );
    
    print('🚀 تم بدء مراقبة الأداء');
  }

  /// إيقاف مراقبة الأداء
  void stopMonitoring() {
    _performanceTimer?.cancel();
    _memoryCleanupTimer?.cancel();
    _isMonitoring = false;
    
    print('⏹️ تم إيقاف مراقبة الأداء');
  }

  /// بدء قياس عملية
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
  }

  /// انتهاء قياس عملية
  void endOperation(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime == null) return;
    
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    
    // حفظ مدة العملية
    _operationDurations.putIfAbsent(operationName, () => []).add(duration);
    
    // الحفاظ على حد أقصى من السجلات
    final durations = _operationDurations[operationName]!;
    if (durations.length > _maxOperationHistory) {
      durations.removeAt(0);
    }
    
    _operationStartTimes.remove(operationName);
    
    // تحذير للعمليات البطيئة
    if (duration > 5000) { // أكثر من 5 ثوان
      print('⚠️ عملية بطيئة: $operationName استغرقت ${duration}ms');
    }
  }

  /// قياس عملية مع callback
  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startOperation(operationName);
    try {
      final result = await operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName);
      rethrow;
    }
  }

  /// الحصول على إحصائيات العملية
  OperationStats? getOperationStats(String operationName) {
    final durations = _operationDurations[operationName];
    final count = _operationCounts[operationName];
    
    if (durations == null || durations.isEmpty || count == null) {
      return null;
    }
    
    final avgDuration = durations.reduce((a, b) => a + b) / durations.length;
    final minDuration = durations.reduce((a, b) => a < b ? a : b);
    final maxDuration = durations.reduce((a, b) => a > b ? a : b);
    
    return OperationStats(
      operationName: operationName,
      totalCalls: count,
      averageDuration: avgDuration.round(),
      minDuration: minDuration,
      maxDuration: maxDuration,
      recentDurations: List.from(durations),
    );
  }

  /// الحصول على جميع إحصائيات الأداء
  Map<String, OperationStats> getAllStats() {
    final stats = <String, OperationStats>{};
    
    for (final operationName in _operationCounts.keys) {
      final operationStats = getOperationStats(operationName);
      if (operationStats != null) {
        stats[operationName] = operationStats;
      }
    }
    
    return stats;
  }

  /// تنظيف الذاكرة
  Future<void> _performMemoryCleanup() async {
    try {
      print('🧹 بدء تنظيف الذاكرة...');
      
      // تنظيف سجلات الأداء القديمة
      _cleanupOldPerformanceData();
      
      // تشغيل garbage collector إذا كان متاحاً
      if (!kIsWeb) {
        // في Flutter، يمكن اقتراح تشغيل GC
        // لكن لا يمكن إجباره مباشرة
      }
      
      // تنظيف الكاش إذا كان الاستخدام مرتفعاً
      final memoryUsage = await _getMemoryUsage();
      if (memoryUsage > 100 * 1024 * 1024) { // أكثر من 100 MB
        await _requestCacheCleanup();
      }
      
      print('✅ تم تنظيف الذاكرة');
    } catch (e) {
      print('❌ خطأ في تنظيف الذاكرة: $e');
    }
  }

  /// تنظيف بيانات الأداء القديمة
  void _cleanupOldPerformanceData() {
    final cutoffTime = DateTime.now().subtract(Duration(hours: 1));
    
    // إزالة العمليات القديمة
    _operationStartTimes.removeWhere((_, startTime) => 
        startTime.isBefore(cutoffTime));
    
    // تقليل حجم سجلات المدة
    for (final durations in _operationDurations.values) {
      while (durations.length > _maxOperationHistory ~/ 2) {
        durations.removeAt(0);
      }
    }
  }

  /// تقدير استخدام الذاكرة
  Future<int> _getMemoryUsage() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // تقدير تقريبي بناءً على حجم البيانات المخزنة
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        
        int totalSize = 0;
        for (final key in keys) {
          final value = prefs.get(key);
          if (value is String) {
            totalSize += value.length * 2; // تقدير UTF-16
          }
        }
        
        return totalSize;
      }
    } catch (e) {
      print('⚠️ فشل في تقدير استخدام الذاكرة: $e');
    }
    
    return 0;
  }

  /// طلب تنظيف الكاش
  Future<void> _requestCacheCleanup() async {
    try {
      // يمكن إضافة استدعاء لخدمة الكاش هنا
      print('🧹 طلب تنظيف الكاش بسبب ارتفاع استخدام الذاكرة');
    } catch (e) {
      print('❌ خطأ في طلب تنظيف الكاش: $e');
    }
  }

  /// إنتاج تقرير الأداء
  Future<void> _generatePerformanceReport() async {
    try {
      final stats = getAllStats();
      
      if (stats.isEmpty) return;
      
      print('📊 تقرير الأداء:');
      
      // ترتيب العمليات حسب متوسط الوقت
      final sortedStats = stats.entries.toList()
        ..sort((a, b) => b.value.averageDuration.compareTo(a.value.averageDuration));
      
      for (final entry in sortedStats.take(5)) { // أبطأ 5 عمليات
        final stat = entry.value;
        print('  ${stat.operationName}: ${stat.averageDuration}ms متوسط، ${stat.totalCalls} استدعاء');
      }
      
      // حفظ التقرير للمراجعة اللاحقة
      await _savePerformanceReport(stats);
      
    } catch (e) {
      print('❌ خطأ في إنتاج تقرير الأداء: $e');
    }
  }

  /// حفظ تقرير الأداء
  Future<void> _savePerformanceReport(Map<String, OperationStats> stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportData = <String, dynamic>{};
      
      for (final entry in stats.entries) {
        reportData[entry.key] = entry.value.toMap();
      }
      
      await prefs.setString('performance_report', reportData.toString());
      await prefs.setInt('performance_report_time', DateTime.now().millisecondsSinceEpoch);
      
    } catch (e) {
      print('❌ خطأ في حفظ تقرير الأداء: $e');
    }
  }

  /// الحصول على تقرير الأداء المحفوظ
  Future<Map<String, OperationStats>?> getSavedPerformanceReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportString = prefs.getString('performance_report');
      final reportTime = prefs.getInt('performance_report_time');
      
      if (reportString == null || reportTime == null) return null;
      
      // التحقق من عمر التقرير (لا يزيد عن 24 ساعة)
      final reportAge = DateTime.now().millisecondsSinceEpoch - reportTime;
      if (reportAge > 24 * 60 * 60 * 1000) return null;
      
      // يمكن تحسين هذا لاحقاً لتحليل البيانات المحفوظة
      return getAllStats();
      
    } catch (e) {
      print('❌ خطأ في استرجاع تقرير الأداء: $e');
      return null;
    }
  }

  /// تحسين الأداء التلقائي
  Future<void> optimizePerformance() async {
    try {
      print('⚡ بدء تحسين الأداء التلقائي...');
      
      // تحليل الأداء الحالي
      final stats = getAllStats();
      final slowOperations = stats.entries
          .where((entry) => entry.value.averageDuration > 3000)
          .map((entry) => entry.key)
          .toList();
      
      if (slowOperations.isNotEmpty) {
        print('⚠️ عمليات بطيئة مكتشفة: $slowOperations');
        
        // اقتراحات التحسين
        for (final operation in slowOperations) {
          _suggestOptimization(operation, stats[operation]!);
        }
      }
      
      // تنظيف الذاكرة
      await _performMemoryCleanup();
      
      // تحسين الكاش
      await _optimizeCache();
      
      print('✅ تم تحسين الأداء');
      
    } catch (e) {
      print('❌ خطأ في تحسين الأداء: $e');
    }
  }

  /// اقتراح تحسينات للعمليات البطيئة
  void _suggestOptimization(String operationName, OperationStats stats) {
    print('💡 اقتراحات تحسين للعملية: $operationName');
    
    if (operationName.contains('firebase') || operationName.contains('network')) {
      print('  - استخدام الكاش لتقليل طلبات الشبكة');
      print('  - تحسين timeout للطلبات');
    }
    
    if (operationName.contains('cache') || operationName.contains('storage')) {
      print('  - ضغط البيانات المخزنة');
      print('  - تنظيف الكاش القديم');
    }
    
    if (operationName.contains('lesson') || operationName.contains('load')) {
      print('  - التحميل التدريجي للبيانات');
      print('  - استخدام pagination');
    }
    
    if (stats.totalCalls > 100 && stats.averageDuration > 1000) {
      print('  - تحسين الخوارزمية أو إضافة كاش');
    }
  }

  /// تحسين الكاش
  Future<void> _optimizeCache() async {
    try {
      // يمكن إضافة استدعاء لخدمة الكاش هنا
      print('🔧 تحسين إعدادات الكاش...');
    } catch (e) {
      print('❌ خطأ في تحسين الكاش: $e');
    }
  }

  /// إعادة تعيين إحصائيات الأداء
  void resetStats() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _operationCounts.clear();
    
    print('🔄 تم إعادة تعيين إحصائيات الأداء');
  }

  /// تصدير إحصائيات الأداء
  Map<String, dynamic> exportStats() {
    final export = <String, dynamic>{};
    
    export['timestamp'] = DateTime.now().toIso8601String();
    export['operations'] = <String, dynamic>{};
    
    for (final entry in getAllStats().entries) {
      export['operations'][entry.key] = entry.value.toMap();
    }
    
    return export;
  }

  void dispose() {
    stopMonitoring();
  }
}

/// إحصائيات العملية
class OperationStats {
  final String operationName;
  final int totalCalls;
  final int averageDuration;
  final int minDuration;
  final int maxDuration;
  final List<int> recentDurations;

  OperationStats({
    required this.operationName,
    required this.totalCalls,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.recentDurations,
  });

  Map<String, dynamic> toMap() {
    return {
      'operationName': operationName,
      'totalCalls': totalCalls,
      'averageDuration': averageDuration,
      'minDuration': minDuration,
      'maxDuration': maxDuration,
      'recentDurations': recentDurations,
    };
  }

  factory OperationStats.fromMap(Map<String, dynamic> map) {
    return OperationStats(
      operationName: map['operationName'] ?? '',
      totalCalls: map['totalCalls'] ?? 0,
      averageDuration: map['averageDuration'] ?? 0,
      minDuration: map['minDuration'] ?? 0,
      maxDuration: map['maxDuration'] ?? 0,
      recentDurations: List<int>.from(map['recentDurations'] ?? []),
    );
  }

  bool get isSlowOperation => averageDuration > 3000;
  bool get isFrequentOperation => totalCalls > 50;
  
  double get performanceScore {
    // نقاط الأداء من 0 إلى 100
    final durationScore = (5000 - averageDuration).clamp(0, 5000) / 5000 * 100;
    return durationScore.clamp(0, 100);
  }
}
