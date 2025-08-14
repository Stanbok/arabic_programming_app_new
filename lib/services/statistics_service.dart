import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/lesson_attempt_model.dart';
import '../services/firebase_service.dart';

/// Service for managing lesson statistics and attempt tracking
class StatisticsService {
  static const String _attemptsKey = 'lesson_attempts_local';
  static const String _statisticsKey = 'lesson_statistics_local';

  /// Record a new lesson attempt
  static Future<LessonAttemptModel> recordAttempt({
    required String lessonId,
    required String userId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required List<int> answers,
    required int scoringTimeMs,
    required int xpAwarded,
    required int gemsAwarded,
  }) async {
    final attemptId = '${lessonId}_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final isPassed = score >= 70;
    
    // Get previous attempts to determine attempt number and status
    final previousAttempts = await getAttempts(lessonId, userId);
    final attemptNumber = previousAttempts.length + 1;
    final hasPassedBefore = previousAttempts.any((a) => a.isPassed);
    final isFirstPass = isPassed && !hasPassedBefore;
    
    String status;
    if (isPassed) {
      status = isFirstPass ? 'passed' : 'retake_after_pass';
    } else {
      status = 'failed';
    }

    final attempt = LessonAttemptModel(
      id: attemptId,
      lessonId: lessonId,
      userId: userId,
      score: score,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      answers: answers,
      attemptedAt: DateTime.now(),
      attemptNumber: attemptNumber,
      isPassed: isPassed,
      isFirstPass: isFirstPass,
      xpAwarded: xpAwarded,
      gemsAwarded: gemsAwarded,
      scoringTimeMs: scoringTimeMs,
      status: status,
    );

    // Save locally
    await _saveAttemptLocally(attempt);
    
    // Save to Firebase in background
    _saveAttemptToFirebase(attempt);
    
    print('📊 تم تسجيل المحاولة: ${attempt.id} - النتيجة: $score% - أول نجاح: $isFirstPass');
    
    return attempt;
  }

  /// Get all attempts for a specific lesson and user
  static Future<List<LessonAttemptModel>> getAttempts(String lessonId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptsJson = prefs.getString(_attemptsKey) ?? '[]';
      final List<dynamic> attemptsList = json.decode(attemptsJson);
      
      final attempts = attemptsList
          .map((json) => LessonAttemptModel.fromMap(json))
          .where((attempt) => attempt.lessonId == lessonId && attempt.userId == userId)
          .toList();
      
      attempts.sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
      return attempts;
    } catch (e) {
      print('خطأ في جلب المحاولات: $e');
      return [];
    }
  }

  /// Get statistics for a specific lesson
  static Future<LessonStatistics> getLessonStatistics(String lessonId, String userId) async {
    final attempts = await getAttempts(lessonId, userId);
    return LessonStatistics.fromAttempts(lessonId, attempts);
  }

  /// Get overall user statistics
  static Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptsJson = prefs.getString(_attemptsKey) ?? '[]';
      final List<dynamic> attemptsList = json.decode(attemptsJson);
      
      final userAttempts = attemptsList
          .map((json) => LessonAttemptModel.fromMap(json))
          .where((attempt) => attempt.userId == userId)
          .toList();

      if (userAttempts.isEmpty) {
        return {
          'totalAttempts': 0,
          'totalLessonsCompleted': 0,
          'averageScore': 0.0,
          'totalXPEarned': 0,
          'totalGemsEarned': 0,
          'averageScoringTime': 0.0,
          'completionRate': 0.0,
        };
      }

      final completedLessons = userAttempts
          .where((a) => a.isPassed)
          .map((a) => a.lessonId)
          .toSet()
          .length;

      final totalScore = userAttempts.map((a) => a.score).reduce((a, b) => a + b);
      final averageScore = totalScore / userAttempts.length;
      
      final totalXP = userAttempts.map((a) => a.xpAwarded).reduce((a, b) => a + b);
      final totalGems = userAttempts.map((a) => a.gemsAwarded).reduce((a, b) => a + b);
      
      final totalScoringTime = userAttempts.map((a) => a.scoringTimeMs).reduce((a, b) => a + b);
      final averageScoringTime = totalScoringTime / userAttempts.length;

      print('📈 إحصائيات المستخدم $userId:');
      print('   - إجمالي المحاولات: ${userAttempts.length}');
      print('   - الدروس المكتملة: $completedLessons');
      print('   - متوسط النتائج: ${averageScore.toStringAsFixed(1)}%');
      print('   - إجمالي XP: $totalXP');
      print('   - إجمالي الجواهر: $totalGems');

      return {
        'totalAttempts': userAttempts.length,
        'totalLessonsCompleted': completedLessons,
        'averageScore': averageScore,
        'totalXPEarned': totalXP,
        'totalGemsEarned': totalGems,
        'averageScoringTime': averageScoringTime,
        'completionRate': completedLessons > 0 ? (completedLessons / 50.0) * 100 : 0.0, // Assuming 50 total lessons
      };
    } catch (e) {
      print('خطأ في حساب إحصائيات المستخدم: $e');
      return {
        'totalAttempts': 0,
        'totalLessonsCompleted': 0,
        'averageScore': 0.0,
        'totalXPEarned': 0,
        'totalGemsEarned': 0,
        'averageScoringTime': 0.0,
        'completionRate': 0.0,
      };
    }
  }

  /// Calculate XP multiplier for post-pass retakes - إصلاح المشكلة الأولى (تصحيح حساب إعادة المحاولة)
  static Future<double> calculateRetakeMultiplier(String lessonId, String userId) async {
    try {
      final attempts = await getAttempts(lessonId, userId);
      
      print('🔍 حساب مضاعف إعادة المحاولة للدرس $lessonId');
      print('   - عدد المحاولات السابقة: ${attempts.length}');
      
      if (attempts.isEmpty) {
        print('   - لا توجد محاولات سابقة، مضاعف كامل: 1.0');
        return 1.0;
      }
      
      // البحث عن أول نجاح
      final firstPassIndex = attempts.indexWhere((a) => a.isPassed);
      if (firstPassIndex == -1) {
        print('   - لم ينجح من قبل، مضاعف كامل: 1.0');
        return 1.0; // لم ينجح من قبل، مضاعف كامل
      }
      
      print('   - أول نجاح في المحاولة رقم: ${firstPassIndex + 1}');
      
      // حساب عدد المحاولات الناجحة بعد النجاح الأول (التصحيح الأساسي)
      final successfulRetakesAfterFirstPass = attempts
          .skip(firstPassIndex + 1)
          .where((a) => a.isPassed) // فقط المحاولات الناجحة
          .length;
      
      print('   - عدد إعادات المحاولة الناجحة بعد النجاح الأول: $successfulRetakesAfterFirstPass');
      
      // تطبيق مضاعف التقليل بناءً على عدد إعادات المحاولة الناجحة
      double multiplier;
      switch (successfulRetakesAfterFirstPass) {
        case 0: 
          multiplier = 0.3; // 30% للإعادة الناجحة الأولى
          break;
        case 1: 
          multiplier = 0.2; // 20% للإعادة الناجحة الثانية
          break;
        case 2: 
          multiplier = 0.1; // 10% للإعادة الناجحة الثالثة
          break;
        default: 
          multiplier = 0.05; // 5% للإعادات الناجحة اللاحقة
          break;
      }
      
      print('   - المضاعف المطبق: ${multiplier}x (${(multiplier * 100).round()}%)');
      return multiplier;
    } catch (e) {
      print('❌ خطأ في حساب مضاعف إعادة المحاولة: $e');
      return 1.0;
    }
  }

  /// Save attempt locally
  static Future<void> _saveAttemptLocally(LessonAttemptModel attempt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptsJson = prefs.getString(_attemptsKey) ?? '[]';
      final List<dynamic> attemptsList = json.decode(attemptsJson);
      
      attemptsList.add(attempt.toMap());
      
      await prefs.setString(_attemptsKey, json.encode(attemptsList));
      print('💾 تم حفظ المحاولة محلياً: ${attempt.id}');
    } catch (e) {
      print('خطأ في حفظ المحاولة محلياً: $e');
    }
  }

  /// Save attempt to Firebase in background
  static Future<void> _saveAttemptToFirebase(LessonAttemptModel attempt) async {
    try {
      await FirebaseService.saveAttempt(attempt);
      print('✅ تم حفظ المحاولة في Firebase: ${attempt.id}');
    } catch (e) {
      print('⚠️ فشل في حفظ المحاولة في Firebase: $e');
    }
  }

  /// Reset all statistics (for testing) - إصلاح المشكلة الرابعة
  static Future<void> resetAllStatistics(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_attemptsKey);
      await prefs.remove(_statisticsKey);
      
      // إزالة جميع البيانات المتعلقة بالإحصائيات
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('lesson_attempts_') || 
            key.startsWith('lesson_statistics_') ||
            key.startsWith('quiz_') ||
            key.contains('completed_quizzes')) {
          await prefs.remove(key);
        }
      }
      
      print('🔄 تم إعادة تعيين جميع الإحصائيات للمستخدم: $userId');
    } catch (e) {
      print('خطأ في إعادة تعيين الإحصائيات: $e');
    }
  }

  /// Force refresh statistics from Firebase - إضافة جديدة لحل مشكلة التحديث
  static Future<void> refreshStatisticsFromFirebase(String userId) async {
    try {
      print('🔄 تحديث الإحصائيات من Firebase...');
      
      // محاولة جلب البيانات من Firebase مع timeout قصير
      final firebaseAttempts = await FirebaseService.getUserAttempts(userId)
          .timeout(const Duration(seconds: 5), onTimeout: () => <LessonAttemptModel>[]);
      
      if (firebaseAttempts.isNotEmpty) {
        // دمج البيانات المحلية مع Firebase
        final prefs = await SharedPreferences.getInstance();
        final localAttemptsJson = prefs.getString(_attemptsKey) ?? '[]';
        final List<dynamic> localAttemptsList = json.decode(localAttemptsJson);
        
        final localAttempts = localAttemptsList
            .map((json) => LessonAttemptModel.fromMap(json))
            .toList();
        
        // إضافة المحاولات من Firebase التي لا توجد محلياً
        final allAttempts = <LessonAttemptModel>[];
        allAttempts.addAll(localAttempts);
        
        for (var firebaseAttempt in firebaseAttempts) {
          if (!allAttempts.any((local) => local.id == firebaseAttempt.id)) {
            allAttempts.add(firebaseAttempt);
          }
        }
        
        // حفظ البيانات المدمجة
        final mergedAttemptsJson = allAttempts.map((a) => a.toMap()).toList();
        await prefs.setString(_attemptsKey, json.encode(mergedAttemptsJson));
        
        print('✅ تم تحديث الإحصائيات من Firebase: ${firebaseAttempts.length} محاولة جديدة');
      }
    } catch (e) {
      print('⚠️ فشل في تحديث الإحصائيات من Firebase: $e');
    }
  }
}
