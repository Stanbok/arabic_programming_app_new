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
          'averageScoringTime': 0,
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
        'averageScoringTime': 0,
        'completionRate': 0.0,
      };
    }
  }

  /// Calculate XP multiplier for post-pass retakes
  static double calculateRetakeMultiplier(String lessonId, String userId) async {
    final attempts = await getAttempts(lessonId, userId);
    
    if (attempts.isEmpty) return 1.0;
    
    // Find first pass
    final firstPassIndex = attempts.indexWhere((a) => a.isPassed);
    if (firstPassIndex == -1) return 1.0; // No pass yet, full XP
    
    final firstPassTime = attempts[firstPassIndex].attemptedAt;
    final now = DateTime.now();
    
    // Count retakes within 24 hours of first pass
    final retakesWithin24h = attempts
        .skip(firstPassIndex + 1)
        .where((a) => now.difference(firstPassTime).inHours < 24)
        .length;
    
    // Apply decay multiplier
    switch (retakesWithin24h) {
      case 0: return 0.3; // 30% for first retake
      case 1: return 0.2; // 20% for second retake
      case 2: return 0.1; // 10% for third retake
      default: return 0.0; // 0% for fourth+ retakes
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

  /// Reset all statistics (for testing)
  static Future<void> resetAllStatistics(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_attemptsKey);
      await prefs.remove(_statisticsKey);
      print('تم إعادة تعيين جميع الإحصائيات للمستخدم: $userId');
    } catch (e) {
      print('خطأ في إعادة تعيين الإحصائيات: $e');
    }
  }
}
