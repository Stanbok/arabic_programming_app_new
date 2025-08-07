import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/lesson_model.dart';
import '../models/quiz_result_model.dart';
import '../models/progress_model.dart';

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
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
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
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  // Lesson Methods
  static Future<List<LessonModel>> getLessons({int? level}) async {
    try {
      Query query = _firestore
          .collection('lessons')
          .where('isPublished', isEqualTo: true)
          .orderBy('level')
          .orderBy('order');
      
      if (level != null) {
        query = query.where('level', isEqualTo: level);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => LessonModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب الدروس: ${e.toString()}');
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

  // Progress Methods
  static Future<void> updateLessonProgress(
      String userId, String lessonId, ProgressModel progress) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(lessonId)
          .set(progress.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('خطأ في حفظ التقدم: ${e.toString()}');
    }
  }

  static Future<ProgressModel?> getLessonProgress(String userId, String lessonId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(lessonId)
          .get();
      
      if (doc.exists) {
        return ProgressModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب التقدم: ${e.toString()}');
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
      
      // Update user XP and gems
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'xp': FieldValue.increment(xp),
        'gems': FieldValue.increment(gems),
      });
      
      // Add transaction log
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
      
      // Delete progress subcollection
      final progressSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .get();
      
      for (var doc in progressSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
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

  // Analytics and Time Tracking
  static Future<void> logSlideCompletion(String userId, String lessonId, String slideId) async {
    try {
      // Log analytics event
      await _firestore.collection('analytics').add({
        'userId': userId,
        'lessonId': lessonId,
        'slideId': slideId,
        'event': 'slide_completed',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Analytics logging shouldn't break the app
      print('Analytics logging failed: $e');
    }
  }

  static Future<void> updateTimeSpent(String userId, String lessonId, int timeSpent) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(lessonId)
          .update({
        'timeSpent': FieldValue.increment(timeSpent),
      });
    } catch (e) {
      throw Exception('خطأ في تحديث الوقت المستغرق: ${e.toString()}');
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
}
