import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/lesson_model.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static const String _localStatsKey = 'local_analytics_data';
  static const String _sessionStartKey = 'session_start_time';
  
  // Session Management
  static Future<void> startSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStart = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_sessionStartKey, sessionStart);
    
    await _analytics.logEvent(
      name: 'session_start',
      parameters: {
        'user_id': userId,
        'timestamp': sessionStart,
        'app_version': '1.0.0',
      },
    );
  }
  
  static Future<void> endSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStart = prefs.getInt(_sessionStartKey) ?? DateTime.now().millisecondsSinceEpoch;
    final sessionEnd = DateTime.now().millisecondsSinceEpoch;
    final sessionDuration = sessionEnd - sessionStart;
    
    await _analytics.logEvent(
      name: 'session_end',
      parameters: {
        'user_id': userId,
        'session_duration': sessionDuration,
        'timestamp': sessionEnd,
      },
    );
    
    await _updateLocalStats('session_duration', sessionDuration);
  }
  
  // Learning Events
  static Future<void> logLessonStart(String userId, String lessonId, int unitNumber) async {
    await _analytics.logEvent(
      name: 'lesson_start',
      parameters: {
        'user_id': userId,
        'lesson_id': lessonId,
        'unit_number': unitNumber,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    
    await _updateLocalStats('lessons_started', 1);
  }
  
  static Future<void> logLessonComplete(String userId, String lessonId, int unitNumber, int timeSpent) async {
    await _analytics.logEvent(
      name: 'lesson_complete',
      parameters: {
        'user_id': userId,
        'lesson_id': lessonId,
        'unit_number': unitNumber,
        'time_spent': timeSpent,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    
    await _updateLocalStats('lessons_completed', 1);
    await _updateLocalStats('total_study_time', timeSpent);
  }
  
  // Quiz Events
  static Future<void> logQuizStart(String userId, String lessonId, int questionCount) async {
    await _analytics.logEvent(
      name: 'quiz_start',
      parameters: {
        'user_id': userId,
        'lesson_id': lessonId,
        'question_count': questionCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  static Future<void> logQuizComplete(String userId, String lessonId, {
    required int correctAnswers,
    required int totalQuestions,
    required double score,
    required int timeSpent,
    required bool isRetake,
    required int attemptNumber,
  }) async {
    await _analytics.logEvent(
      name: 'quiz_complete',
      parameters: {
        'user_id': userId,
        'lesson_id': lessonId,
        'correct_answers': correctAnswers,
        'total_questions': totalQuestions,
        'score': score,
        'time_spent': timeSpent,
        'is_retake': isRetake,
        'attempt_number': attemptNumber,
        'passed': score >= 70.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    
    await _updateLocalStats('quizzes_taken', 1);
    if (score >= 70.0) {
      await _updateLocalStats('quizzes_passed', 1);
    }
    await _updateLocalStats('total_quiz_time', timeSpent);
  }
  
  // Progress Events
  static Future<void> logLevelUp(String userId, int newLevel, int totalXP) async {
    await _analytics.logEvent(
      name: 'level_up',
      parameters: {
        'user_id': userId,
        'new_level': newLevel,
        'total_xp': totalXP,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    
    await _updateLocalStats('level_ups', 1);
  }
  
  static Future<void> logXPGained(String userId, int xpGained, String source) async {
    await _analytics.logEvent(
      name: 'xp_gained',
      parameters: {
        'user_id': userId,
        'xp_gained': xpGained,
        'source': source, // 'lesson_complete', 'quiz_pass', 'level_bonus'
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  static Future<void> logGemsEarned(String userId, int gemsEarned, String source) async {
    await _analytics.logEvent(
      name: 'gems_earned',
      parameters: {
        'user_id': userId,
        'gems_earned': gemsEarned,
        'source': source,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  static Future<void> logGemsSpent(String userId, int gemsSpent, String item) async {
    await _analytics.logEvent(
      name: 'gems_spent',
      parameters: {
        'user_id': userId,
        'gems_spent': gemsSpent,
        'item': item,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  // Error Events
  static Future<void> logError(String userId, String errorType, String errorMessage, {
    String? screen,
    String? action,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'user_id': userId,
        'error_type': errorType,
        'error_message': errorMessage,
        'screen': screen ?? 'unknown',
        'action': action ?? 'unknown',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  // Performance Events
  static Future<void> logPerformanceMetric(String metricName, int value, {
    String? screen,
    Map<String, dynamic>? additionalData,
  }) async {
    final parameters = <String, dynamic>{
      'metric_name': metricName,
      'value': value,
      'screen': screen ?? 'unknown',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (additionalData != null) {
      parameters.addAll(additionalData);
    }
    
    await _analytics.logEvent(
      name: 'performance_metric',
      parameters: parameters,
    );
  }
  
  // Local Statistics Management
  static Future<void> _updateLocalStats(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_localStatsKey) ?? '{}';
      final stats = Map<String, dynamic>.from(jsonDecode(statsJson));
      
      if (stats.containsKey(key)) {
        if (value is int && stats[key] is int) {
          stats[key] = (stats[key] as int) + value;
        } else {
          stats[key] = value;
        }
      } else {
        stats[key] = value;
      }
      
      await prefs.setString(_localStatsKey, jsonEncode(stats));
    } catch (e) {
      print('Error updating local stats: $e');
    }
  }
  
  static Future<Map<String, dynamic>> getLocalStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_localStatsKey) ?? '{}';
      return Map<String, dynamic>.from(jsonDecode(statsJson));
    } catch (e) {
      print('Error getting local stats: $e');
      return {};
    }
  }
  
  // User Properties
  static Future<void> setUserProperties(UserModel user) async {
    await _analytics.setUserProperty(
      name: 'user_level',
      value: user.currentLevel.toString(),
    );
    
    await _analytics.setUserProperty(
      name: 'total_xp',
      value: user.totalXP.toString(),
    );
    
    await _analytics.setUserProperty(
      name: 'total_gems',
      value: user.gems.toString(),
    );
    
    await _analytics.setUserProperty(
      name: 'lessons_completed',
      value: user.completedLessons.length.toString(),
    );
  }
  
  // Advanced Analytics
  static Future<Map<String, dynamic>> generateUserReport(String userId) async {
    final localStats = await getLocalStats();
    final now = DateTime.now();
    
    return {
      'user_id': userId,
      'report_date': now.toIso8601String(),
      'sessions_count': localStats['sessions_count'] ?? 0,
      'total_study_time': localStats['total_study_time'] ?? 0,
      'lessons_started': localStats['lessons_started'] ?? 0,
      'lessons_completed': localStats['lessons_completed'] ?? 0,
      'quizzes_taken': localStats['quizzes_taken'] ?? 0,
      'quizzes_passed': localStats['quizzes_passed'] ?? 0,
      'level_ups': localStats['level_ups'] ?? 0,
      'completion_rate': _calculateCompletionRate(localStats),
      'average_session_duration': _calculateAverageSessionDuration(localStats),
      'quiz_success_rate': _calculateQuizSuccessRate(localStats),
    };
  }
  
  static double _calculateCompletionRate(Map<String, dynamic> stats) {
    final started = stats['lessons_started'] ?? 0;
    final completed = stats['lessons_completed'] ?? 0;
    return started > 0 ? (completed / started) * 100 : 0.0;
  }
  
  static double _calculateAverageSessionDuration(Map<String, dynamic> stats) {
    final totalTime = stats['total_study_time'] ?? 0;
    final sessions = stats['sessions_count'] ?? 0;
    return sessions > 0 ? totalTime / sessions : 0.0;
  }
  
  static double _calculateQuizSuccessRate(Map<String, dynamic> stats) {
    final taken = stats['quizzes_taken'] ?? 0;
    final passed = stats['quizzes_passed'] ?? 0;
    return taken > 0 ? (passed / taken) * 100 : 0.0;
  }
  
  // Data Export
  static Future<void> exportAnalyticsData(String userId) async {
    final report = await generateUserReport(userId);
    
    await _analytics.logEvent(
      name: 'data_export',
      parameters: {
        'user_id': userId,
        'export_type': 'analytics_report',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    
    // يمكن إضافة منطق تصدير البيانات هنا
    print('Analytics Report: ${jsonEncode(report)}');
  }
}
