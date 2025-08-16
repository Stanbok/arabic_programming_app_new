import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/lesson_model.dart';
import '../models/quiz_result_model.dart';
import '../models/enhanced_quiz_result.dart';

import 'dart:io';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  static final Map<String, dynamic> _queryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  static void _configureFirestore() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  static Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('خطأ في تسجيل الدخول: ${e.toString()}');
    }
  }

  static Future<UserCredential?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('خطأ في إنشاء الحساب: ${e.toString()}');
    }
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('خطأ في إرسال رابط إعادة تعيين كلمة المرور: ${e.toString()}');
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  static Future<void> createUserDocument(UserModel user) async {
    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(user.id);
      
      batch.set(userRef, user.toMap());
      
      // إنشاء مجموعات فرعية فارغة لتحسين الأداء
      final transactionsRef = userRef.collection('transactions').doc('init');
      batch.set(transactionsRef, {
        'type': 'init',
        'timestamp': FieldValue.serverTimestamp(),
        'isPlaceholder': true,
      });
      
      await batch.commit();
      
      // حذف المستند المؤقت
      await transactionsRef.delete();
    } catch (e) {
      throw Exception('خطأ في حفظ بيانات المستخدم: ${e.toString()}');
    }
  }

  static Future<UserModel?> getUserData(String userId) async {
    final cacheKey = 'user_$userId';
    
    // فحص الكاش أولاً
    if (_isCacheValid(cacheKey)) {
      return _queryCache[cacheKey] as UserModel?;
    }
    
    try {
      return await retryOperation(() async {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(userId)
            .get(const GetOptions(source: Source.serverAndCache));
        
        UserModel? user;
        if (doc.exists) {
          user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
        
        // حفظ في الكاش
        _updateCache(cacheKey, user);
        return user;
      });
    } catch (e) {
      throw Exception('خطأ في جلب بيانات المستخدم: ${e.toString()}');
    }
  }

  static Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      
      // إبطال الكاش المتعلق بالمستخدم
      _invalidateUserCache(userId);
    } catch (e) {
      throw Exception('خطأ في تحديث بيانات المستخدم: ${e.toString()}');
    }
  }

  static Stream<UserModel?> getUserDataStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots(includeMetadataChanges: false) // تقليل التحديثات غير الضرورية
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            final user = UserModel.fromMap(doc.data()!);
            // تحديث الكاش مع البيانات الجديدة
            _updateCache('user_$userId', user);
            return user;
          }
          return null;
        })
        .handleError((error) {
          print('خطأ في stream بيانات المستخدم: $error');
          throw Exception('خطأ في الاستماع لبيانات المستخدم: $error');
        });
  }

  static Future<List<LessonModel>> getLessons({int? unit}) async {
    final cacheKey = 'lessons_${unit ?? 'all'}';
    
    // فحص الكاش أولاً
    if (_isCacheValid(cacheKey)) {
      return List<LessonModel>.from(_queryCache[cacheKey]);
    }
    
    try {
      // استخدام composite index للاستعلام المحسن
      Query query = _firestore
          .collection('lessons')
          .where('isPublished', isEqualTo: true);
      
      if (unit != null) {
        query = query.where('unit', isEqualTo: unit);
      }
      
      // ترتيب محسن
      query = query.orderBy('unit').orderBy('order');
      
      // استخدام كاش محلي أولاً
      QuerySnapshot snapshot = await query.get(const GetOptions(source: Source.cache));
      
      // إذا لم يوجد في الكاش، جلب من الخادم
      if (snapshot.docs.isEmpty) {
        snapshot = await query.get(const GetOptions(source: Source.server));
      }
      
      final lessons = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              return LessonModel.fromMap(data);
            } catch (e) {
              print('❌ خطأ في معالجة الدرس ${doc.id}: $e');
              return null;
            }
          })
          .where((lesson) => lesson != null)
          .cast<LessonModel>()
          .toList();
      
      // حفظ في الكاش
      _updateCache(cacheKey, lessons);
      
      return lessons;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('خطأ في الصلاحيات: تأكد من قواعد الأمان في Firestore');
      } else if (e.toString().contains('unavailable')) {
        throw Exception('خطأ في الاتصال: تأكد من اتصال الإنترنت');
      } else {
        throw Exception('خطأ في جلب الدروس: ${e.toString()}');
      }
    }
  }

  static Future<LessonModel?> getLesson(String lessonId) async {
    final cacheKey = 'lesson_$lessonId';
    
    if (_isCacheValid(cacheKey)) {
      return _queryCache[cacheKey] as LessonModel?;
    }
    
    try {
      DocumentSnapshot doc = await _firestore
          .collection('lessons')
          .doc(lessonId)
          .get(const GetOptions(source: Source.serverAndCache));
      
      LessonModel? lesson;
      if (doc.exists) {
        lesson = LessonModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      
      _updateCache(cacheKey, lesson);
      return lesson;
    } catch (e) {
      throw Exception('خطأ في جلب الدرس: ${e.toString()}');
    }
  }

  static Future<void> saveQuizResult(
      String userId, String lessonId, QuizResultModel result) async {
    try {
      final batch = _firestore.batch();
      
      // حفظ نتيجة الاختبار
      final quizRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .doc(lessonId);
      
      batch.set(quizRef, result.toMap());
      
      // تحديث قائمة الدروس المكتملة إذا نجح
      if (result.isPassed) {
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'completedLessons': FieldValue.arrayUnion([lessonId]),
          'lastActivityAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      // إبطال الكاش المتعلق بالمستخدم
      _invalidateUserCache(userId);
    } catch (e) {
      throw Exception('خطأ في حفظ نتيجة الاختبار: ${e.toString()}');
    }
  }

  static Future<void> saveEnhancedQuizResult(
      String userId, String lessonId, EnhancedQuizResult result) async {
    try {
      final batch = _firestore.batch();
      
      // حفظ النتيجة المحسنة
      final enhancedQuizRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('enhancedQuizResults')
          .doc(result.id);
      
      batch.set(enhancedQuizRef, result.toJson());
      
      // حفظ النتيجة العادية للتوافق مع النظام القديم
      final basicResult = QuizResultModel(
        lessonId: lessonId,
        score: result.score,
        totalQuestions: result.totalQuestions,
        percentage: result.percentage,
        completedAt: result.completedAt,
        isPassed: result.isPassed,
      );
      
      final quizRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .doc(lessonId);
      
      batch.set(quizRef, basicResult.toMap());
      
      // تحديث بيانات المستخدم إذا نجح
      if (result.isPassed) {
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'completedLessons': FieldValue.arrayUnion([lessonId]),
          'lastActivityAt': FieldValue.serverTimestamp(),
          'totalQuizzesTaken': FieldValue.increment(1),
          'totalTimeSpent': FieldValue.increment(result.timeSpent),
        });
      }
      
      await batch.commit();
      
      // إبطال الكاش المتعلق بالمستخدم
      _invalidateUserCache(userId);
    } catch (e) {
      throw Exception('خطأ في حفظ النتيجة المحسنة: ${e.toString()}');
    }
  }

  static Future<List<QuizResultModel>> getQuizResults(String userId, {int limit = 50}) async {
    final cacheKey = 'quiz_results_$userId';
    
    if (_isCacheValid(cacheKey)) {
      return List<QuizResultModel>.from(_queryCache[cacheKey]);
    }
    
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.serverAndCache));
      
      final results = snapshot.docs
          .map((doc) => QuizResultModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      _updateCache(cacheKey, results);
      return results;
    } catch (e) {
      throw Exception('خطأ في جلب نتائج الاختبارات: ${e.toString()}');
    }
  }

  static Future<List<EnhancedQuizResult>> getEnhancedQuizResults(
      String userId, {int limit = 50}) async {
    final cacheKey = 'enhanced_quiz_results_$userId';
    
    if (_isCacheValid(cacheKey)) {
      return List<EnhancedQuizResult>.from(_queryCache[cacheKey]);
    }
    
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('enhancedQuizResults')
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.serverAndCache));
      
      final results = snapshot.docs
          .map((doc) => EnhancedQuizResult.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      _updateCache(cacheKey, results);
      return results;
    } catch (e) {
      throw Exception('خطأ في جلب النتائج المحسنة: ${e.toString()}');
    }
  }

  static Future<List<EnhancedQuizResult>> getEnhancedQuizResultsForLesson(
      String userId, String lessonId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('enhancedQuizResults')
          .where('lessonId', isEqualTo: lessonId)
          .orderBy('completedAt', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));
      
      return snapshot.docs
          .map((doc) => EnhancedQuizResult.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب نتائج الدرس: ${e.toString()}');
    }
  }

  static Future<void> addXPAndGems(String userId, int xp, int gems, String reason) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('المستخدم غير موجود');
        }
        
        final userData = userDoc.data()!;
        final currentXP = userData['xp'] ?? 0;
        final currentLevel = userData['currentLevel'] ?? 1;
        final newXP = currentXP + xp;
        final newLevel = _calculateLevelFromXP(newXP);
        
        // تحديث بيانات المستخدم
        final updateData = {
          'xp': newXP,
          'gems': FieldValue.increment(gems),
          'currentLevel': newLevel,
          'lastActivityAt': FieldValue.serverTimestamp(),
        };
        
        // مكافأة ترقية المستوى
        if (newLevel > currentLevel) {
          updateData['gems'] = FieldValue.increment(gems + 20);
        }
        
        transaction.update(userRef, updateData);
        
        // إضافة سجل المعاملة
        final transactionRef = userRef.collection('transactions').doc();
        transaction.set(transactionRef, {
          'type': xp > 0 ? 'reward' : 'expense',
          'xpAmount': xp,
          'gemsAmount': gems + (newLevel > currentLevel ? 20 : 0),
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
      
      // إبطال الكاش
      _invalidateUserCache(userId);
    } catch (e) {
      throw Exception('خطأ في تحديث النقاط: ${e.toString()}');
    }
  }

  static Future<String> uploadProfileImage(String userId, String imagePath) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      await ref.putFile(File(imagePath));
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('خطأ في رفع الصورة: ${e.toString()}');
    }
  }

  static Future<void> resetUserProgress(String userId) async {
    try {
      // استخدام batch operations متعددة لتجنب حدود Firestore
      final batches = <WriteBatch>[];
      var currentBatch = _firestore.batch();
      var operationCount = 0;
      
      // إعادة تعيين بيانات المستخدم الأساسية
      final userRef = _firestore.collection('users').doc(userId);
      currentBatch.update(userRef, {
        'xp': 0,
        'gems': 0,
        'currentLevel': 1,
        'completedLessons': [],
        'lastActivityAt': FieldValue.serverTimestamp(),
      });
      operationCount++;
      
      // حذف نتائج الاختبارات
      final quizSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .limit(400) // حد Firestore للعمليات في batch واحد
          .get();
      
      for (var doc in quizSnapshot.docs) {
        if (operationCount >= 400) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          operationCount = 0;
        }
        currentBatch.delete(doc.reference);
        operationCount++;
      }
      
      // حذف المعاملات
      final transactionSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .limit(400 - operationCount)
          .get();
      
      for (var doc in transactionSnapshot.docs) {
        if (operationCount >= 400) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          operationCount = 0;
        }
        currentBatch.delete(doc.reference);
        operationCount++;
      }
      
      batches.add(currentBatch);
      
      // تنفيذ جميع العمليات
      for (final batch in batches) {
        await batch.commit();
      }
      
      // إبطال الكاش
      _invalidateUserCache(userId);
    } catch (e) {
      throw Exception('خطأ في إعادة تعيين الحساب: ${e.toString()}');
    }
  }

  static Future<void> checkAndUpdateLevel(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data()!;
      final currentXP = userData['xp'] ?? 0;
      final currentLevel = userData['currentLevel'] ?? 1;
      
      int newLevel = _calculateLevelFromXP(currentXP);
      
      if (newLevel > currentLevel) {
        await _firestore.collection('users').doc(userId).update({
          'currentLevel': newLevel,
        });
        
        await addXPAndGems(userId, 0, 20, 'مكافأة الوصول للمستوى $newLevel');
      }
    } catch (e) {
      throw Exception('خطأ في تحديث المستوى: ${e.toString()}');
    }
  }

  static int _calculateLevelFromXP(int xp) {
    if (xp < 100) return 1;
    if (xp < 300) return 2;
    if (xp < 600) return 3;
    if (xp < 1000) return 4;
    return (xp / 500).floor() + 1;
  }

  static Future<bool> checkConnection() async {
    try {
      await _firestore.doc('test/connection').get(
        const GetOptions(source: Source.server)
      ).timeout(const Duration(seconds: 3));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        
        // Exponential backoff
        final delay = initialDelay * (1 << i);
        await Future.delayed(delay);
      }
    }
    throw Exception('فشل في العملية بعد $maxRetries محاولات');
  }

  static bool _isCacheValid(String key) {
    if (!_queryCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheValidDuration;
  }

  static void _updateCache(String key, dynamic value) {
    _queryCache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  static void _invalidateUserCache(String userId) {
    final keysToRemove = _queryCache.keys
        .where((key) => key.contains(userId))
        .toList();
    
    for (final key in keysToRemove) {
      _queryCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  static void clearCache() {
    _queryCache.clear();
    _cacheTimestamps.clear();
  }

  static void initialize() {
    _configureFirestore();
  }
}
