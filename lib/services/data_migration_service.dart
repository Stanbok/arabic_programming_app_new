import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'cache_service.dart';

/// خدمة توحيد البيانات ومعالجة التضارب بين level/unit
class DataMigrationService {
  static final DataMigrationService _instance = DataMigrationService._internal();
  factory DataMigrationService() => _instance;
  DataMigrationService._internal();

  static const String _migrationVersionKey = 'data_migration_version';
  static const int _currentMigrationVersion = 2;
  
  bool _isMigrationInProgress = false;
  final List<String> _migrationLog = [];

  /// تهيئة خدمة توحيد البيانات
  Future<void> initialize() async {
    await _checkAndRunMigrations();
  }

  /// فحص وتشغيل عمليات التوحيد المطلوبة
  Future<void> _checkAndRunMigrations() async {
    if (_isMigrationInProgress) return;
    
    try {
      _isMigrationInProgress = true;
      
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_migrationVersionKey) ?? 0;
      
      print('🔄 فحص إصدار البيانات: الحالي=$currentVersion، المطلوب=$_currentMigrationVersion');
      
      if (currentVersion < _currentMigrationVersion) {
        await _runMigrations(currentVersion);
        await prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
        print('✅ تم تحديث البيانات إلى الإصدار $_currentMigrationVersion');
      } else {
        print('✅ البيانات محدثة بالفعل');
      }
      
    } catch (e) {
      print('❌ خطأ في عملية توحيد البيانات: $e');
      _migrationLog.add('خطأ: $e');
    } finally {
      _isMigrationInProgress = false;
    }
  }

  /// تشغيل عمليات التوحيد
  Future<void> _runMigrations(int fromVersion) async {
    print('🚀 بدء عملية توحيد البيانات من الإصدار $fromVersion');
    
    // Migration 1: توحيد level إلى unit في البيانات المحلية
    if (fromVersion < 1) {
      await _migrateLevelToUnitInLocalData();
    }
    
    // Migration 2: توحيد البيانات في Firebase وتنظيف الكاش
    if (fromVersion < 2) {
      await _migrateLevelToUnitInFirebase();
      await _cleanupOldCacheData();
    }
  }

  /// توحيد level إلى unit في البيانات المحلية
  Future<void> _migrateLevelToUnitInLocalData() async {
    try {
      print('📱 بدء توحيد البيانات المحلية...');
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // البحث عن البيانات التي تحتوي على level
      final keysToMigrate = keys.where((key) => 
          key.startsWith('cached_lesson_') || 
          key.startsWith('cached_lessons') ||
          key.startsWith('local_')).toList();
      
      int migratedCount = 0;
      
      for (final key in keysToMigrate) {
        try {
          final data = prefs.getString(key);
          if (data != null) {
            final migratedData = _migrateLevelToUnitInJson(data);
            if (migratedData != data) {
              await prefs.setString(key, migratedData);
              migratedCount++;
            }
          }
        } catch (e) {
          print('⚠️ خطأ في توحيد المفتاح $key: $e');
          _migrationLog.add('خطأ في توحيد $key: $e');
        }
      }
      
      print('✅ تم توحيد $migratedCount عنصر في البيانات المحلية');
      _migrationLog.add('تم توحيد $migratedCount عنصر محلي');
      
    } catch (e) {
      print('❌ خطأ في توحيد البيانات المحلية: $e');
      _migrationLog.add('خطأ في البيانات المحلية: $e');
    }
  }

  /// توحيد level إلى unit في Firebase
  Future<void> _migrateLevelToUnitInFirebase() async {
    try {
      print('☁️ بدء توحيد البيانات في Firebase...');
      
      // فحص الاتصال بـ Firebase
      final isConnected = await FirebaseService.checkConnection();
      if (!isConnected) {
        print('⚠️ لا يوجد اتصال بـ Firebase، سيتم التوحيد لاحقاً');
        return;
      }
      
      // توحيد الدروس في Firebase
      await _migrateLessonsInFirebase();
      
      // توحيد بيانات المستخدمين
      await _migrateUsersInFirebase();
      
      print('✅ تم توحيد البيانات في Firebase');
      _migrationLog.add('تم توحيد البيانات في Firebase');
      
    } catch (e) {
      print('❌ خطأ في توحيد Firebase: $e');
      _migrationLog.add('خطأ في Firebase: $e');
    }
  }

  /// توحيد الدروس في Firebase
  Future<void> _migrateLessonsInFirebase() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // جلب جميع الدروس التي تحتوي على level
      final lessonsQuery = await firestore
          .collection('lessons')
          .where('level', isNull: false)
          .get()
          .timeout(const Duration(seconds: 30));
      
      if (lessonsQuery.docs.isEmpty) {
        print('📚 لا توجد دروس تحتاج لتوحيد في Firebase');
        return;
      }
      
      final batch = firestore.batch();
      int batchCount = 0;
      
      for (final doc in lessonsQuery.docs) {
        try {
          final data = doc.data();
          final level = data['level'];
          
          if (level != null && data['unit'] == null) {
            // إضافة unit وإزالة level
            batch.update(doc.reference, {
              'unit': level,
              'level': FieldValue.delete(),
            });
            
            batchCount++;
            
            // تنفيذ الدفعة كل 500 عملية
            if (batchCount >= 500) {
              await batch.commit();
              batchCount = 0;
              print('📦 تم تنفيذ دفعة من 500 عملية توحيد');
            }
          }
        } catch (e) {
          print('⚠️ خطأ في توحيد الدرس ${doc.id}: $e');
        }
      }
      
      // تنفيذ الدفعة المتبقية
      if (batchCount > 0) {
        await batch.commit();
      }
      
      print('✅ تم توحيد ${lessonsQuery.docs.length} درس في Firebase');
      
    } catch (e) {
      print('❌ خطأ في توحيد دروس Firebase: $e');
    }
  }

  /// توحيد بيانات المستخدمين في Firebase
  Future<void> _migrateUsersInFirebase() async {
    try {
      // هذه العملية تتطلب صلاحيات إدارية، لذا سنتركها للمطور
      print('👥 توحيد بيانات المستخدمين يتطلب صلاحيات إدارية');
      _migrationLog.add('تم تخطي توحيد بيانات المستخدمين (يتطلب صلاحيات إدارية)');
      
    } catch (e) {
      print('❌ خطأ في توحيد بيانات المستخدمين: $e');
    }
  }

  /// تنظيف بيانات الكاش القديمة
  Future<void> _cleanupOldCacheData() async {
    try {
      print('🧹 تنظيف بيانات الكاش القديمة...');
      
      // مسح الكاش القديم لإجبار إعادة التحميل بالبيانات الموحدة
      await CacheService.clearCache();
      
      // إزالة المفاتيح القديمة من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final oldKeys = keys.where((key) => 
          key.contains('_level_') || 
          key.startsWith('old_') ||
          key.contains('legacy_')).toList();
      
      for (final key in oldKeys) {
        await prefs.remove(key);
      }
      
      print('✅ تم تنظيف ${oldKeys.length} مفتاح قديم');
      _migrationLog.add('تم تنظيف ${oldKeys.length} مفتاح قديم');
      
    } catch (e) {
      print('❌ خطأ في تنظيف الكاش: $e');
    }
  }

  /// توحيد level إلى unit في نص JSON
  String _migrateLevelToUnitInJson(String jsonData) {
    try {
      // استبدال level بـ unit في النص مباشرة
      String migratedData = jsonData;
      
      // استبدال "level": بـ "unit":
      migratedData = migratedData.replaceAllMapped(
        RegExp(r'"level"\s*:\s*(\d+)'),
        (match) => '"unit": ${match.group(1)}',
      );
      
      // إزالة مراجع level القديمة إذا كان unit موجود
      if (migratedData.contains('"unit":')) {
        migratedData = migratedData.replaceAllMapped(
          RegExp(r',\s*"level"\s*:\s*\d+'),
          (match) => '',
        );
      }
      
      return migratedData;
      
    } catch (e) {
      print('⚠️ خطأ في توحيد JSON: $e');
      return jsonData; // إرجاع البيانات الأصلية في حالة الخطأ
    }
  }

  /// توحيد درس واحد
  LessonModel migrateLessonModel(Map<String, dynamic> lessonData) {
    // إنشاء نسخة من البيانات للتعديل
    final migratedData = Map<String, dynamic>.from(lessonData);
    
    // التحقق من وجود level وعدم وجود unit
    if (migratedData.containsKey('level') && !migratedData.containsKey('unit')) {
      migratedData['unit'] = migratedData['level'];
      migratedData.remove('level');
      
      print('🔄 تم توحيد الدرس: ${migratedData['id']} من level إلى unit');
    }
    
    // التأكد من وجود unit
    if (!migratedData.containsKey('unit')) {
      migratedData['unit'] = 1; // قيمة افتراضية
      print('⚠️ تم إضافة unit افتراضي للدرس: ${migratedData['id']}');
    }
    
    return LessonModel.fromMap(migratedData);
  }

  /// توحيد قائمة الدروس
  List<LessonModel> migrateLessonsList(List<Map<String, dynamic>> lessonsData) {
    final migratedLessons = <LessonModel>[];
    
    for (final lessonData in lessonsData) {
      try {
        final migratedLesson = migrateLessonModel(lessonData);
        migratedLessons.add(migratedLesson);
      } catch (e) {
        print('❌ خطأ في توحيد الدرس: $e');
        _migrationLog.add('خطأ في توحيد درس: $e');
      }
    }
    
    return migratedLessons;
  }

  /// التحقق من صحة البيانات الموحدة
  Future<ValidationResult> validateMigratedData() async {
    try {
      print('🔍 بدء التحقق من صحة البيانات الموحدة...');
      
      final issues = <String>[];
      int validLessons = 0;
      int invalidLessons = 0;
      
      // فحص البيانات المحلية
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith('cached_lesson_')) {
          try {
            final data = prefs.getString(key);
            if (data != null) {
              final jsonData = jsonDecode(data);
              
              if (jsonData is Map<String, dynamic>) {
                if (jsonData.containsKey('level') && !jsonData.containsKey('unit')) {
                  issues.add('الدرس $key ما زال يحتوي على level بدلاً من unit');
                  invalidLessons++;
                } else if (jsonData.containsKey('unit')) {
                  validLessons++;
                } else {
                  issues.add('الدرس $key لا يحتوي على unit أو level');
                  invalidLessons++;
                }
              }
            }
          } catch (e) {
            issues.add('خطأ في فحص $key: $e');
            invalidLessons++;
          }
        }
      }
      
      // فحص الكاش
      final cachedLessons = await CacheService.getCachedLessons();
      for (final lesson in cachedLessons) {
        if (lesson.unit <= 0) {
          issues.add('الدرس ${lesson.id} يحتوي على unit غير صالح: ${lesson.unit}');
          invalidLessons++;
        } else {
          validLessons++;
        }
      }
      
      final result = ValidationResult(
        isValid: issues.isEmpty,
        validLessons: validLessons,
        invalidLessons: invalidLessons,
        issues: issues,
        migrationLog: List.from(_migrationLog),
      );
      
      print('📊 نتائج التحقق: ${result.validLessons} صالح، ${result.invalidLessons} غير صالح');
      
      return result;
      
    } catch (e) {
      print('❌ خطأ في التحقق من البيانات: $e');
      return ValidationResult(
        isValid: false,
        validLessons: 0,
        invalidLessons: 0,
        issues: ['خطأ في التحقق: $e'],
        migrationLog: List.from(_migrationLog),
      );
    }
  }

  /// إصلاح البيانات التالفة
  Future<void> repairCorruptedData() async {
    try {
      print('🔧 بدء إصلاح البيانات التالفة...');
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int repairedCount = 0;
      
      for (final key in keys) {
        if (key.startsWith('cached_lesson_')) {
          try {
            final data = prefs.getString(key);
            if (data != null) {
              final jsonData = jsonDecode(data);
              
              if (jsonData is Map<String, dynamic>) {
                bool needsRepair = false;
                
                // إصلاح level إلى unit
                if (jsonData.containsKey('level') && !jsonData.containsKey('unit')) {
                  jsonData['unit'] = jsonData['level'];
                  jsonData.remove('level');
                  needsRepair = true;
                }
                
                // إضافة unit افتراضي إذا لم يكن موجوداً
                if (!jsonData.containsKey('unit')) {
                  jsonData['unit'] = 1;
                  needsRepair = true;
                }
                
                // التأكد من صحة القيم
                if (jsonData['unit'] is! int || jsonData['unit'] <= 0) {
                  jsonData['unit'] = 1;
                  needsRepair = true;
                }
                
                if (needsRepair) {
                  await prefs.setString(key, jsonEncode(jsonData));
                  repairedCount++;
                }
              }
            }
          } catch (e) {
            print('⚠️ خطأ في إصلاح $key: $e');
            // حذف البيانات التالفة
            await prefs.remove(key);
          }
        }
      }
      
      print('✅ تم إصلاح $repairedCount عنصر');
      _migrationLog.add('تم إصلاح $repairedCount عنصر');
      
    } catch (e) {
      print('❌ خطأ في إصلاح البيانات: $e');
    }
  }

  /// الحصول على تقرير التوحيد
  MigrationReport getMigrationReport() {
    return MigrationReport(
      isCompleted: !_isMigrationInProgress,
      currentVersion: _currentMigrationVersion,
      migrationLog: List.from(_migrationLog),
      timestamp: DateTime.now(),
    );
  }

  /// إعادة تشغيل عملية التوحيد
  Future<void> forceMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationVersionKey);
    _migrationLog.clear();
    await _checkAndRunMigrations();
  }
}

/// نتيجة التحقق من البيانات
class ValidationResult {
  final bool isValid;
  final int validLessons;
  final int invalidLessons;
  final List<String> issues;
  final List<String> migrationLog;

  ValidationResult({
    required this.isValid,
    required this.validLessons,
    required this.invalidLessons,
    required this.issues,
    required this.migrationLog,
  });

  double get validationScore => 
      (validLessons + invalidLessons) > 0 
          ? (validLessons / (validLessons + invalidLessons)) * 100 
          : 0;

  String get validationGrade {
    if (validationScore >= 95) return 'ممتاز';
    if (validationScore >= 80) return 'جيد';
    if (validationScore >= 60) return 'مقبول';
    return 'ضعيف';
  }
}

/// تقرير التوحيد
class MigrationReport {
  final bool isCompleted;
  final int currentVersion;
  final List<String> migrationLog;
  final DateTime timestamp;

  MigrationReport({
    required this.isCompleted,
    required this.currentVersion,
    required this.migrationLog,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'isCompleted': isCompleted,
      'currentVersion': currentVersion,
      'migrationLog': migrationLog,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
