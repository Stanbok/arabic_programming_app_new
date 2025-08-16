import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enhanced_lesson_model.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class EnhancedFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<EnhancedLessonModel?> getEnhancedLesson(String lessonId) async {
    try {
      // محاولة تحميل من Firebase أولاً
      final doc = await _firestore.collection('enhanced_lessons').doc(lessonId).get();
      
      if (doc.exists) {
        return EnhancedLessonModel.fromMap(doc.data()!);
      }

      // إذا لم يوجد في Firebase، تحميل من الأصول المحلية
      return await _loadFromAssets(lessonId);
    } catch (e) {
      // في حالة الخطأ، تحميل من الأصول المحلية
      return await _loadFromAssets(lessonId);
    }
  }

  static Future<EnhancedLessonModel?> _loadFromAssets(String lessonId) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/python/lessons/$lessonId.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return EnhancedLessonModel.fromMap(jsonData);
    } catch (e) {
      print('خطأ في تحميل الدرس من الأصول: $e');
      return null;
    }
  }

  static Future<List<EnhancedLessonModel>> getEnhancedLessons({int? unit}) async {
    try {
      Query query = _firestore.collection('enhanced_lessons');
      
      if (unit != null) {
        query = query.where('unit', isEqualTo: unit);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        return EnhancedLessonModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('خطأ في تحميل الدروس المحسنة: $e');
      return [];
    }
  }

  static Future<void> saveEnhancedLessonProgress(
    String userId,
    String lessonId,
    Map<String, dynamic> progress,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('enhanced_lesson_progress')
          .doc(lessonId)
          .set({
        'progress': progress,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('خطأ في حفظ تقدم الدرس المحسن: $e');
    }
  }

  static Future<Map<String, dynamic>?> getEnhancedLessonProgress(
    String userId,
    String lessonId,
  ) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('enhanced_lesson_progress')
          .doc(lessonId)
          .get();

      if (doc.exists) {
        return doc.data()?['progress'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('خطأ في تحميل تقدم الدرس المحسن: $e');
      return null;
    }
  }
}
