import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/lesson_model.dart';
import '../models/quiz_result_model.dart';

import 'dart:io';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Authentication Methods
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

  // User Data Methods
  static Future<void> createUserDocument(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('خطأ في حفظ بيانات المستخدم: ${e.toString()}');
    }
  }

  static Future<UserModel?> getUserData(String userId) async {
    try {
      return await retryOperation(() async {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(userId)
            .get(const GetOptions(source: Source.serverAndCache));
        
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
        return null;
      });
    } catch (e) {
      throw Exception('خطأ في جلب بيانات المستخدم: ${e.toString()}');
    }
  }

  static Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('خطأ في تحديث بيانات المستخدم: ${e.toString()}');
    }
  }

  static Stream<UserModel?> getUserDataStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots(includeMetadataChanges: true)
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return UserModel.fromMap(doc.data()!);
          }
          return null;
        })
        .handleError((error) {
          print('خطأ في stream بيانات المستخدم: $error');
          throw Exception('خطأ في الاستماع لبيانات المستخدم: $error');
        });
  }

  // Lesson Methods
  static Future<List<LessonModel>> getLessons({int? unit}) async {
    try {
      print('🔄 جلب الدروس من Firestore...');
      
      Query query = _firestore
          .collection('lessons')
          .where('isPublished', isEqualTo: true)
          .orderBy('unit')
          .orderBy('order');
      
      if (unit != null) {
        query = query.where('unit', isEqualTo: unit);
      }

      print('🔍 تنفيذ الاستعلام...');
      QuerySnapshot snapshot = await query.get();
      
      print('📦 تم جلب ${snapshot.docs.length} مستند');
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ لا توجد دروس في قاعدة البيانات!');
        print('💡 تأكد من:');
        print('  - وجود مجموعة "lessons" في Firestore');
        print('  - وجود دروس مع isPublished = true');
        print('  - صحة قواعد الأمان في Firestore');
      }
      
      final lessons = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              print('📄 معالجة الدرس: ${data['title'] ?? 'بدون عنوان'}');
              return LessonModel.fromMap(data);
            } catch (e) {
              print('❌ خطأ في معالجة الدرس ${doc.id}: $e');
              return null;
            }
          })
          .where((lesson) => lesson != null)
          .cast<LessonModel>()
          .toList();
      
      print('✅ تم معالجة ${lessons.length} درس بنجاح');
      return lessons;
    } catch (e) {
      print('❌ خطأ في جلب الدروس: $e');
      
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
    try {
      DocumentSnapshot doc = await _firestore.collection('lessons').doc(lessonId).get();
      if (doc.exists) {
        return LessonModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب الدرس: ${e.toString()}');
    }
  }

  // Quiz Methods
  static Future<void> saveQuizResult(
      String userId, String lessonId, QuizResultModel result) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .doc(lessonId)
          .set(result.toMap());
    } catch (e) {
      throw Exception('خطأ في حفظ نتيجة الاختبار: ${e.toString()}');
    }
  }

  static Future<List<QuizResultModel>> getQuizResults(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .orderBy('completedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => QuizResultModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب نتائج الاختبارات: ${e.toString()}');
    }
  }

  // XP and Gems Methods
  static Future<void> addXPAndGems(String userId, int xp, int gems, String reason) async {
    try {
      final batch = _firestore.batch();
      
      // جلب بيانات المستخدم الحالية
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      if (userData != null) {
        final currentXP = userData['xp'] ?? 0;
        final currentLevel = userData['currentLevel'] ?? 1;
        final newXP = currentXP + xp;
        
        // حساب المستوى الجديد
        final newLevel = _calculateLevelFromXP(newXP);
        
        // تحديث XP والجواهر والمستوى
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'xp': FieldValue.increment(xp),
          'gems': FieldValue.increment(gems),
          'currentLevel': newLevel, // تحديث المستوى
        });
        
        // إضافة مكافأة ترقية المستوى
        if (newLevel > currentLevel) {
          batch.update(userRef, {
            'gems': FieldValue.increment(20), // مكافأة 20 جوهرة للترقية
          });
          
          // سجل معاملة الترقية
          final levelUpTransactionRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .doc();
          
          batch.set(levelUpTransactionRef, {
            'type': 'level_up',
            'xpAmount': 0,
            'gemsAmount': 20,
            'reason': 'ترقية للمستوى $newLevel',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // إذا لم توجد بيانات المستخدم، أنشئ مستخدم جديد
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'xp': FieldValue.increment(xp),
          'gems': FieldValue.increment(gems),
          'currentLevel': _calculateLevelFromXP(xp),
        });
      }
      
      // إضافة سجل المعاملة
      final transactionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc();
      
      batch.set(transactionRef, {
        'type': xp > 0 ? 'xp_gain' : 'gems_spent',
        'xpAmount': xp,
        'gemsAmount': gems,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
    } catch (e) {
      throw Exception('خطأ في تحديث النقاط: ${e.toString()}');
    }
  }

  // Storage Methods
  static Future<String> uploadProfileImage(String userId, String imagePath) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      await ref.putFile(File(imagePath));
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('خطأ في رفع الصورة: ${e.toString()}');
    }
  }

  // Settings Methods
  static Future<void> resetUserProgress(String userId) async {
    try {
      final batch = _firestore.batch();
      
      // Reset user stats
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'xp': 0,
        'gems': 0,
        'currentLevel': 1,
        'completedLessons': [],
      });
      
      // Delete quiz results subcollection
      final quizSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .get();
      
      for (var doc in quizSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('خطأ في إعادة تعيين الحساب: ${e.toString()}');
    }
  }

  // Level Management
  static Future<void> checkAndUpdateLevel(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data()!;
      final currentXP = userData['xp'] ?? 0;
      final currentLevel = userData['currentLevel'] ?? 1;
      
      // Calculate new level based on XP
      int newLevel = _calculateLevelFromXP(currentXP);
      
      if (newLevel > currentLevel) {
        await _firestore.collection('users').doc(userId).update({
          'currentLevel': newLevel,
        });
        
        // Award bonus gems for level up
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

  // Share functionality
  static Future<void> grantShareReward(String userId) async {
    try {
      await addXPAndGems(userId, 0, 50, 'مشاركة التطبيق');
      
      // Save share timestamp
      await _firestore.collection('users').doc(userId).update({
        'lastShareAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('خطأ في منح مكافأة المشاركة: ${e.toString()}');
    }
  }

  // التحقق من اتصال الشبكة
  static Future<bool> checkConnection() async {
    try {
      await _firestore.doc('test/connection').get();
      return true;
    } catch (e) {
      return false;
    }
  }

  // إعادة المحاولة مع التأخير
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(delay * (i + 1));
      }
    }
    throw Exception('فشل في العملية بعد $maxRetries محاولات');
  }
}
