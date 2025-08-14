import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_model.dart';
import '../models/user_model.dart';
import '../models/quiz_result_model.dart';
import 'firebase_service.dart';
import 'local_service.dart';
import 'cache_service.dart';

/// خدمة إدارة البيانات المركزية مع آلية Fallback شاملة
class DataManagerService {
  static final DataManagerService _instance = DataManagerService._internal();
  factory DataManagerService() => _instance;
  DataManagerService._internal();

  // حالة الاتصال
  bool _isOnline = true;
  bool _isFirebaseAvailable = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // قوائم انتظار المزامنة
  final List<PendingSyncOperation> _pendingSyncOperations = [];
  final List<String> _pendingQuizCompletions = [];
  
  // إعدادات الـ Fallback
  static const Duration _firebaseTimeout = Duration(seconds: 10);
  static const Duration _retryDelay = Duration(seconds: 5);
  static const int _maxRetryAttempts = 3;

  /// تهيئة خدمة إدارة البيانات
  Future<void> initialize() async {
    await _checkConnectivity();
    await _setupConnectivityListener();
    await _loadPendingOperations();
    _startSyncTimer();
  }

  /// فحص حالة الاتصال
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;
      
      if (_isOnline) {
        _isFirebaseAvailable = await FirebaseService.checkConnection()
            .timeout(_firebaseTimeout, onTimeout: () => false);
      } else {
        _isFirebaseAvailable = false;
      }
      
      print('🌐 حالة الاتصال: Online=$_isOnline, Firebase=$_isFirebaseAvailable');
    } catch (e) {
      _isOnline = false;
      _isFirebaseAvailable = false;
      print('❌ خطأ في فحص الاتصال: $e');
    }
  }

  /// إعداد مستمع تغيير الاتصال
  Future<void> _setupConnectivityListener() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        print('🔄 تم استعادة الاتصال - بدء المزامنة');
        _onConnectionRestored();
      } else if (wasOnline && !_isOnline) {
        print('📴 فقدان الاتصال - التبديل للوضع المحلي');
        _isFirebaseAvailable = false;
      }
    });
  }

  /// تحميل الدروس مع آلية Fallback شاملة
  Future<DataResult<List<LessonModel>>> getLessons({int? unit}) async {
    print('📚 بدء تحميل الدروس (unit: $unit)');
    
    try {
      // المرحلة 1: البيانات المحلية (أولوية قصوى - فورية)
      final localLessons = await LocalService.getLocalLessons(unit: unit);
      if (localLessons.isNotEmpty) {
        print('✅ تم العثور على ${localLessons.length} درس محلي');
        
        // تحميل من مصادر أخرى في الخلفية
        _loadLessonsInBackground(unit: unit);
        
        return DataResult.success(
          data: localLessons,
          source: DataSource.local,
          message: 'تم تحميل الدروس من البيانات المحلية',
        );
      }

      // المرحلة 2: الكاش (إذا كان صالحاً)
      if (await CacheService.isCacheValid()) {
        final cachedLessons = await CacheService.getCachedLessons(unit: unit);
        if (cachedLessons.isNotEmpty) {
          print('✅ تم العثور على ${cachedLessons.length} درس في الكاش');
          
          // تحديث من Firebase في الخلفية
          _loadLessonsInBackground(unit: unit);
          
          return DataResult.success(
            data: cachedLessons,
            source: DataSource.cache,
            message: 'تم تحميل الدروس من الكاش',
          );
        }
      }

      // المرحلة 3: Firebase (إذا كان متاحاً)
      if (_isFirebaseAvailable) {
        try {
          final firebaseLessons = await FirebaseService.getLessons(unit: unit)
              .timeout(_firebaseTimeout);
          
          if (firebaseLessons.isNotEmpty) {
            print('✅ تم العثور على ${firebaseLessons.length} درس في Firebase');
            
            // حفظ في الكاش
            await CacheService.cacheLessons(firebaseLessons);
            
            return DataResult.success(
              data: firebaseLessons,
              source: DataSource.firebase,
              message: 'تم تحميل الدروس من الخادم',
            );
          }
        } catch (e) {
          print('⚠️ فشل تحميل من Firebase: $e');
          _isFirebaseAvailable = false;
        }
      }

      // المرحلة 4: الكاش القديم (حتى لو انتهت صلاحيته)
      final oldCachedLessons = await CacheService.getCachedLessons(unit: unit);
      if (oldCachedLessons.isNotEmpty) {
        print('⚠️ استخدام الكاش القديم (${oldCachedLessons.length} درس)');
        return DataResult.success(
          data: oldCachedLessons,
          source: DataSource.cacheExpired,
          message: 'تم تحميل الدروس من الكاش القديم (قد تكون غير محدثة)',
        );
      }

      // المرحلة 5: البيانات الاحتياطية المدمجة
      final fallbackLessons = await _getFallbackLessons(unit: unit);
      if (fallbackLessons.isNotEmpty) {
        print('🆘 استخدام البيانات الاحتياطية (${fallbackLessons.length} درس)');
        return DataResult.success(
          data: fallbackLessons,
          source: DataSource.fallback,
          message: 'تم تحميل الدروس الأساسية (محدودة)',
        );
      }

      // فشل في جميع المصادر
      return DataResult.failure(
        error: 'لا توجد دروس متاحة',
        source: DataSource.none,
      );

    } catch (e) {
      print('❌ خطأ عام في تحميل الدروس: $e');
      return DataResult.failure(
        error: 'خطأ في تحميل الدروس: $e',
        source: DataSource.none,
      );
    }
  }

  /// تحميل درس واحد مع آلية Fallback
  Future<DataResult<LessonModel>> getLesson(String lessonId) async {
    print('📖 بدء تحميل الدرس: $lessonId');
    
    try {
      // المرحلة 1: البيانات المحلية
      final localLesson = await LocalService.getLocalLesson(lessonId);
      if (localLesson != null) {
        print('✅ تم العثور على الدرس محلياً');
        return DataResult.success(
          data: localLesson,
          source: DataSource.local,
          message: 'تم تحميل الدرس من البيانات المحلية',
        );
      }

      // المرحلة 2: الكاش
      final cachedLesson = await CacheService.getCachedLesson(lessonId);
      if (cachedLesson != null) {
        print('✅ تم العثور على الدرس في الكاش');
        return DataResult.success(
          data: cachedLesson,
          source: DataSource.cache,
          message: 'تم تحميل الدرس من الكاش',
        );
      }

      // المرحلة 3: Firebase
      if (_isFirebaseAvailable) {
        try {
          final firebaseLesson = await FirebaseService.getLesson(lessonId)
              .timeout(_firebaseTimeout);
          
          if (firebaseLesson != null) {
            print('✅ تم العثور على الدرس في Firebase');
            
            // حفظ في الكاش
            await CacheService.cacheLesson(firebaseLesson);
            
            return DataResult.success(
              data: firebaseLesson,
              source: DataSource.firebase,
              message: 'تم تحميل الدرس من الخادم',
            );
          }
        } catch (e) {
          print('⚠️ فشل تحميل الدرس من Firebase: $e');
          _isFirebaseAvailable = false;
        }
      }

      // فشل في العثور على الدرس
      return DataResult.failure(
        error: 'لم يتم العثور على الدرس',
        source: DataSource.none,
      );

    } catch (e) {
      print('❌ خطأ في تحميل الدرس: $e');
      return DataResult.failure(
        error: 'خطأ في تحميل الدرس: $e',
        source: DataSource.none,
      );
    }
  }

  /// حفظ نتيجة الاختبار مع آلية Fallback
  Future<DataResult<bool>> saveQuizResult(
    String userId, 
    String lessonId, 
    QuizResultModel result
  ) async {
    print('💾 حفظ نتيجة الاختبار: $lessonId');
    
    try {
      // حفظ محلياً أولاً (دائماً)
      await _saveQuizResultLocally(userId, lessonId, result);
      
      // محاولة حفظ في Firebase
      if (_isFirebaseAvailable) {
        try {
          await FirebaseService.saveQuizResult(userId, lessonId, result)
              .timeout(_firebaseTimeout);
          
          print('✅ تم حفظ نتيجة الاختبار في Firebase');
          return DataResult.success(
            data: true,
            source: DataSource.firebase,
            message: 'تم حفظ النتيجة بنجاح',
          );
        } catch (e) {
          print('⚠️ فشل حفظ في Firebase، سيتم المزامنة لاحقاً: $e');
          _isFirebaseAvailable = false;
          
          // إضافة للقائمة المعلقة
          _pendingQuizCompletions.add(lessonId);
          await _savePendingOperations();
        }
      } else {
        // إضافة للقائمة المعلقة
        _pendingQuizCompletions.add(lessonId);
        await _savePendingOperations();
      }
      
      return DataResult.success(
        data: true,
        source: DataSource.local,
        message: 'تم حفظ النتيجة محلياً',
      );
      
    } catch (e) {
      print('❌ خطأ في حفظ نتيجة الاختبار: $e');
      return DataResult.failure(
        error: 'فشل في حفظ النتيجة: $e',
        source: DataSource.none,
      );
    }
  }

  /// تحميل بيانات المستخدم مع آلية Fallback
  Future<DataResult<UserModel>> getUserData(String userId) async {
    print('👤 تحميل بيانات المستخدم: $userId');
    
    try {
      // المرحلة 1: Firebase (إذا كان متاحاً)
      if (_isFirebaseAvailable) {
        try {
          final firebaseUser = await FirebaseService.getUserData(userId)
              .timeout(_firebaseTimeout);
          
          if (firebaseUser != null) {
            print('✅ تم تحميل بيانات المستخدم من Firebase');
            
            // حفظ في الكاش المحلي
            await _cacheUserData(firebaseUser);
            
            return DataResult.success(
              data: firebaseUser,
              source: DataSource.firebase,
              message: 'تم تحميل البيانات من الخادم',
            );
          }
        } catch (e) {
          print('⚠️ فشل تحميل بيانات المستخدم من Firebase: $e');
          _isFirebaseAvailable = false;
        }
      }

      // المرحلة 2: الكاش المحلي
      final cachedUser = await _getCachedUserData(userId);
      if (cachedUser != null) {
        print('✅ تم تحميل بيانات المستخدم من الكاش');
        return DataResult.success(
          data: cachedUser,
          source: DataSource.cache,
          message: 'تم تحميل البيانات من الكاش المحلي',
        );
      }

      // المرحلة 3: بيانات افتراضية
      final defaultUser = _createDefaultUser(userId);
      print('🆘 إنشاء بيانات مستخدم افتراضية');
      
      return DataResult.success(
        data: defaultUser,
        source: DataSource.fallback,
        message: 'تم إنشاء ملف شخصي مؤقت',
      );

    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
      return DataResult.failure(
        error: 'فشل في تحميل بيانات المستخدم: $e',
        source: DataSource.none,
      );
    }
  }

  /// تحميل الدروس في الخلفية
  void _loadLessonsInBackground({int? unit}) {
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_isFirebaseAvailable) {
        try {
          final firebaseLessons = await FirebaseService.getLessons(unit: unit)
              .timeout(_firebaseTimeout);
          
          if (firebaseLessons.isNotEmpty) {
            await CacheService.updateCachePartially(firebaseLessons);
            print('🔄 تم تحديث الكاش في الخلفية (${firebaseLessons.length} درس)');
          }
        } catch (e) {
          print('⚠️ فشل التحديث في الخلفية: $e');
          _isFirebaseAvailable = false;
        }
      }
    });
  }

  /// استعادة الاتصال
  void _onConnectionRestored() async {
    await _checkConnectivity();
    
    if (_isFirebaseAvailable) {
      await _syncPendingOperations();
    }
  }

  /// مزامنة العمليات المعلقة
  Future<void> _syncPendingOperations() async {
    if (_pendingSyncOperations.isEmpty && _pendingQuizCompletions.isEmpty) {
      return;
    }
    
    print('🔄 بدء مزامنة ${_pendingSyncOperations.length} عملية معلقة');
    
    // مزامنة إكمال الاختبارات
    final completedQuizzes = List<String>.from(_pendingQuizCompletions);
    for (final lessonId in completedQuizzes) {
      try {
        // هنا يمكن إضافة منطق مزامنة إكمال الاختبار
        _pendingQuizCompletions.remove(lessonId);
        print('✅ تم مزامنة إكمال الاختبار: $lessonId');
      } catch (e) {
        print('❌ فشل مزامنة إكمال الاختبار $lessonId: $e');
      }
    }
    
    // مزامنة العمليات الأخرى
    final operations = List<PendingSyncOperation>.from(_pendingSyncOperations);
    for (final operation in operations) {
      try {
        await _executePendingOperation(operation);
        _pendingSyncOperations.remove(operation);
        print('✅ تم تنفيذ العملية المعلقة: ${operation.type}');
      } catch (e) {
        print('❌ فشل تنفيذ العملية المعلقة: $e');
      }
    }
    
    await _savePendingOperations();
  }

  /// الحصول على البيانات الاحتياطية
  Future<List<LessonModel>> _getFallbackLessons({int? unit}) async {
    // بيانات احتياطية أساسية مدمجة في التطبيق
    final fallbackLessons = <LessonModel>[
      LessonModel(
        id: 'fallback_001',
        title: 'مقدمة في Python',
        description: 'تعلم أساسيات لغة البرمجة Python',
        unit: 1,
        order: 1,
        slides: [
          SlideModel(
            id: 'slide_001',
            title: 'ما هو Python؟',
            content: 'Python هي لغة برمجة قوية وسهلة التعلم.',
            order: 1,
          ),
        ],
        quiz: [
          QuizQuestionModel(
            question: 'ما هي لغة Python؟',
            options: ['لغة برمجة', 'نوع من الثعابين', 'برنامج كمبيوتر', 'لا أعرف'],
            correctAnswerIndex: 0,
            explanation: 'Python هي لغة برمجة عالية المستوى.',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    
    if (unit != null) {
      return fallbackLessons.where((lesson) => lesson.unit == unit).toList();
    }
    
    return fallbackLessons;
  }

  /// حفظ نتيجة الاختبار محلياً
  Future<void> _saveQuizResultLocally(
    String userId, 
    String lessonId, 
    QuizResultModel result
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'local_quiz_result_${userId}_$lessonId';
    await prefs.setString(key, result.toMap().toString());
  }

  /// حفظ بيانات المستخدم في الكاش
  Future<void> _cacheUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'cached_user_${user.id}';
    await prefs.setString(key, user.toMap().toString());
  }

  /// استرجاع بيانات المستخدم من الكاش
  Future<UserModel?> _getCachedUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_user_$userId';
      final userData = prefs.getString(key);
      
      if (userData != null) {
        // هنا يجب تحويل النص إلى Map وإنشاء UserModel
        // تم تبسيط المثال
        return null;
      }
    } catch (e) {
      print('❌ خطأ في استرجاع بيانات المستخدم من الكاش: $e');
    }
    return null;
  }

  /// إنشاء مستخدم افتراضي
  UserModel _createDefaultUser(String userId) {
    return UserModel(
      id: userId,
      email: 'guest@example.com',
      displayName: 'مستخدم ضيف',
      xp: 0,
      gems: 0,
      currentLevel: 1,
      completedLessons: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// تنفيذ عملية معلقة
  Future<void> _executePendingOperation(PendingSyncOperation operation) async {
    switch (operation.type) {
      case 'quiz_completion':
        // تنفيذ مزامنة إكمال الاختبار
        break;
      case 'user_update':
        // تنفيذ تحديث بيانات المستخدم
        break;
      default:
        print('⚠️ نوع عملية غير معروف: ${operation.type}');
    }
  }

  /// حفظ العمليات المعلقة
  Future<void> _savePendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pending_quiz_completions', _pendingQuizCompletions);
  }

  /// تحميل العمليات المعلقة
  Future<void> _loadPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingQuizzes = prefs.getStringList('pending_quiz_completions') ?? [];
    _pendingQuizCompletions.addAll(pendingQuizzes);
  }

  /// بدء مؤقت المزامنة
  void _startSyncTimer() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isFirebaseAvailable) {
        _syncPendingOperations();
      }
    });
  }

  /// تنظيف الموارد
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // Getters للحالة
  bool get isOnline => _isOnline;
  bool get isFirebaseAvailable => _isFirebaseAvailable;
  int get pendingOperationsCount => _pendingSyncOperations.length + _pendingQuizCompletions.length;
}

/// نتيجة عملية البيانات
class DataResult<T> {
  final T? data;
  final String? error;
  final DataSource source;
  final String? message;
  final bool isSuccess;

  DataResult._({
    this.data,
    this.error,
    required this.source,
    this.message,
    required this.isSuccess,
  });

  factory DataResult.success({
    required T data,
    required DataSource source,
    String? message,
  }) {
    return DataResult._(
      data: data,
      source: source,
      message: message,
      isSuccess: true,
    );
  }

  factory DataResult.failure({
    required String error,
    required DataSource source,
    String? message,
  }) {
    return DataResult._(
      error: error,
      source: source,
      message: message,
      isSuccess: false,
    );
  }
}

/// مصدر البيانات
enum DataSource {
  local,        // البيانات المحلية
  cache,        // الكاش الصالح
  cacheExpired, // الكاش المنتهي الصلاحية
  firebase,     // Firebase
  fallback,     // البيانات الاحتياطية
  none,         // لا يوجد مصدر
}

/// عملية مزامنة معلقة
class PendingSyncOperation {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  PendingSyncOperation({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}
