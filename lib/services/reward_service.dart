import 'dart:convert';
import '../models/lesson_model.dart';
import '../services/statistics_service.dart';

/// Service for calculating rewards (XP and Gems) from lesson data
/// This is the SINGLE SOURCE OF TRUTH for all reward calculations
class RewardService {
  /// Calculate rewards for completing a lesson quiz
  /// Returns a map with 'xp' and 'gems' keys
  static Future<Map<String, int>> calculateQuizRewards({
    required LessonModel lesson,
    required int score,
    required bool isPassed,
    required String userId,
  }) async {
    // Base rewards come ONLY from lesson JSON data
    final baseXP = lesson.xpReward;
    final baseGems = lesson.gemsReward;
    
    if (!isPassed) {
      // No rewards for failed attempts
      return {'xp': 0, 'gems': 0};
    }
    
    // Check if this is a retake after previous pass
    final attempts = await StatisticsService.getAttempts(lesson.id, userId);
    final hasPassedBefore = attempts.any((a) => a.isPassed);
    
    if (!hasPassedBefore) {
      // First pass - full rewards
      print('🎉 أول نجاح - مكافآت كاملة: ${baseXP} XP, ${baseGems} جوهرة');
      return {'xp': baseXP, 'gems': baseGems};
    }
    
    // This is a retake after pass - apply decay multiplier
    final multiplier = await StatisticsService.calculateRetakeMultiplier(lesson.id, userId);
    final finalXP = (baseXP * multiplier).round();
    final finalGems = (baseGems * multiplier).round();
    
    print('🔄 إعادة محاولة بعد النجاح - مضاعف: ${(multiplier * 100).toInt()}%');
    print('💎 مكافآت مخفضة: ${finalXP} XP, ${finalGems} جوهرة');
    
    return {'xp': finalXP, 'gems': finalGems};
  }
  
  /// Validate lesson data has required reward fields
  static bool validateLessonRewards(Map<String, dynamic> lessonData) {
    if (!lessonData.containsKey('xpReward') || !lessonData.containsKey('gemsReward')) {
      print('⚠️ تحذير: بيانات الدرس لا تحتوي على مكافآت محددة');
      return false;
    }
    
    final xp = lessonData['xpReward'];
    final gems = lessonData['gemsReward'];
    
    if (xp is! int || gems is! int) {
      print('⚠️ تحذير: قيم المكافآت يجب أن تكون أرقام صحيحة');
      return false;
    }
    
    if (xp < 0 || gems < 0) {
      print('⚠️ تحذير: قيم المكافآت لا يمكن أن تكون سالبة');
      return false;
    }
    
    return true;
  }
  
  /// Get default rewards if lesson data is missing reward info
  static Map<String, int> getDefaultRewards() {
    return {'xp': 10, 'gems': 5}; // Default fallback values
  }
  
  /// Log reward calculation for debugging
  static void logRewardCalculation({
    required String lessonId,
    required String userId,
    required int baseXP,
    required int baseGems,
    required int finalXP,
    required int finalGems,
    required bool isRetake,
    double? multiplier,
  }) {
    print('📊 حساب المكافآت:');
    print('   الدرس: $lessonId');
    print('   المستخدم: $userId');
    print('   XP الأساسي: $baseXP');
    print('   الجواهر الأساسية: $baseGems');
    print('   XP النهائي: $finalXP');
    print('   الجواهر النهائية: $finalGems');
    print('   إعادة محاولة: $isRetake');
    if (multiplier != null) {
      print('   المضاعف: ${(multiplier * 100).toInt()}%');
    }
  }
}
