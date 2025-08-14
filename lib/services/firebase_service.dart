import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/lesson_model.dart';
import '../models/quiz_result_model.dart';
import '../models/user_model.dart';
import '../models/lesson_attempt_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check network connectivity
  static Future<bool> checkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Get lessons from Firestore
  static Future<List<LessonModel>> getLessons({int? unit}) async {
    try {
      Query query = _firestore.collection('lessons');
      
      if (unit != null) {
        query = query.where('unit', isEqualTo: unit);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => LessonModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('خطأ في جلب الدروس من Firebase: $e');
      return [];
    }
  }

  /// Get a specific lesson
  static Future<LessonModel?> getLesson(String lessonId) async {
    try {
      final doc = await _firestore.collection('lessons').doc(lessonId).get();
      
      if (doc.exists) {
        return LessonModel.fromMap(doc.data()!);
      }
      
      return null;
    } catch (e) {
      print('خطأ في جلب الدرس من Firebase: $e');
      return null;
    }
  }

  /// Save quiz result
  static Future<void> saveQuizResult(String userId, String lessonId, QuizResultModel result) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('quiz_results')
          .doc(lessonId)
          .set(result.toMap());
      
      print('✅ تم حفظ نتيجة الاختبار في Firebase');
    } catch (e) {
      print('❌ خطأ في حفظ نتيجة الاختبار: $e');
      rethrow;
    }
  }

  /// Save lesson attempt for statistics
  static Future<void> saveAttempt(LessonAttemptModel attempt) async {
    try {
      await _firestore
          .collection('users')
          .doc(attempt.userId)
          .collection('attempts')
          .doc(attempt.id)
          .set(attempt.toMap());
      
      print('✅ تم حفظ المحاولة في Firebase');
    } catch (e) {
      print('❌ خطأ في حفظ المحاولة: $e');
      rethrow;
    }
  }

  /// Get user data
  static Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      
      return null;
    } catch (e) {
      print('خطأ في جلب بيانات المستخدم: $e');
      return null;
    }
  }

  /// Update user data
  static Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      print('✅ تم تحديث بيانات المستخدم في Firebase');
    } catch (e) {
      print('❌ خطأ في تحديث بيانات المستخدم: $e');
      rethrow;
    }
  }

  /// Create user document
  static Future<void> createUserDocument(String userId, UserModel user) async {
    try {
      await _firestore.collection('users').doc(userId).set(user.toMap());
      print('✅ تم إنشاء مستند المستخدم في Firebase');
    } catch (e) {
      print('❌ خطأ في إنشاء مستند المستخدم: $e');
      rethrow;
    }
  }

  /// Get user attempts for statistics
  static Future<List<LessonAttemptModel>> getUserAttempts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attempts')
          .orderBy('attemptedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => LessonAttemptModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('خطأ في جلب محاولات المستخدم: $e');
      return [];
    }
  }

  /// Batch update user progress
  static Future<void> batchUpdateUserProgress(String userId, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(userId);
      
      batch.update(userRef, updates);
      
      await batch.commit();
      print('✅ تم تحديث تقدم المستخدم بشكل مجمع');
    } catch (e) {
      print('❌ خطأ في التحديث المجمع: $e');
      rethrow;
    }
  }

  /// Delete user data (for account deletion)
  static Future<void> deleteUserData(String userId) async {
    try {
      final batch = _firestore.batch();
      
      // Delete user document
      batch.delete(_firestore.collection('users').doc(userId));
      
      // Delete user's quiz results
      final quizResults = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quiz_results')
          .get();
      
      for (var doc in quizResults.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's attempts
      final attempts = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attempts')
          .get();
      
      for (var doc in attempts.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ تم حذف جميع بيانات المستخدم');
    } catch (e) {
      print('❌ خطأ في حذف بيانات المستخدم: $e');
      rethrow;
    }
  }

  /// Sync local data with Firebase
  static Future<void> syncLocalData(String userId, Map<String, dynamic> localData) async {
    try {
      await updateUserData(userId, localData);
      print('🔄 تم مزامنة البيانات المحلية مع Firebase');
    } catch (e) {
      print('⚠️ فشل في مزامنة البيانات المحلية: $e');
    }
  }
}
